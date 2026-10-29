//
//  GeofenceTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-27.
//

import Foundation
import CoreLocation
import Testing
@testable import ecyclelk

// MARK: - Fakes

@MainActor
private final class FakeGeofenceService: GeofenceMonitoring {
    var authorization: CLAuthorizationStatus = .authorizedAlways
    var onEnter: ((String) -> Void)?
    private(set) var alwaysRequests = 0
    private(set) var monitored: [String] = []
    private(set) var stopCount = 0

    func requestAlwaysAccess() { alwaysRequests += 1 }
    func startMonitoring(_ centres: [RecyclingCentre], radius: CLLocationDistance) { monitored = centres.map(\.id) }
    func stopAll() { stopCount += 1; monitored = [] }
}

@MainActor
private final class FakeNotifier: CentreAlertNotifying {
    private(set) var alerts: [(id: String, name: String, categories: [ItemCategory])] = []
    func sendAlert(centreID: String, centreName: String, categories: [ItemCategory]) async {
        alerts.append((centreID, centreName, categories))
    }
}

@MainActor
private final class FakeStore: GeofenceStoring {
    var isEnabled = false
    private var alerts: [String: Date] = [:]
    func lastAlert(for centreID: String) -> Date? { alerts[centreID] }
    func setLastAlert(_ date: Date, for centreID: String) { alerts[centreID] = date }
}

@MainActor
private struct FakeCatalog: CentresCatalog {
    let centres: [RecyclingCentre]
    func loadCentres() throws -> [RecyclingCentre] { centres }
}

@MainActor
private final class FakeItems: ItemsServiceProtocol {
    var records: [ItemRecord]
    init(_ records: [ItemRecord]) { self.records = records }
    func fetchItems(ownerUID: String) throws -> [ItemRecord] { records }
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord { throw ItemsServiceError.notFound }
    func updateItem(id: UUID, with draft: ItemDraft) throws {}
    func deleteItem(id: UUID) throws {}
}

@MainActor
private final class FakeLocation: LocationProviding {
    var authorization: CLAuthorizationStatus = .authorizedWhenInUse
    var location: CLLocation?
    func requestAccess() {}
    func refresh() {}
}

private func item(_ category: ItemCategory, status: ItemStatus = .saved) -> ItemRecord {
    ItemRecord(id: UUID(), name: category.displayName, category: category, condition: .working,
               notes: "", weightKg: 1, dateAdded: Date(), status: status)
}

private func centre(_ id: String, lat: Double, lon: Double, accepts: Set<ItemCategory>) -> RecyclingCentre {
    RecyclingCentre(id: id, name: "Centre \(id)", latitude: lat, longitude: lon, acceptedCategories: accepts)
}

// MARK: - Planner

@MainActor
struct GeofencePlannerTests {
    @Test func onlyCentresThatAcceptTheUsersItemsAreChosen() {
        let centres = [
            centre("phones", lat: 6.9, lon: 79.85, accepts: [.mobilePhones]),
            centre("tvs", lat: 6.9, lon: 79.86, accepts: [.televisions])
        ]
        let chosen = GeofencePlanner.select(centres: centres, categories: [.mobilePhones], near: nil)
        #expect(chosen.map(\.id) == ["phones"])
    }

    @Test func nearestCentresComeFirstAndTheListIsCapped() {
        let user = CLLocation(latitude: 6.90, longitude: 79.85)
        let centres = (0..<30).map { index in
            centre("c\(index)", lat: 6.90 + Double(index) * 0.01, lon: 79.85, accepts: [.laptops])
        }.reversed()
        let chosen = GeofencePlanner.select(centres: Array(centres), categories: [.laptops], near: user)
        #expect(chosen.count == GeofencePlanner.regionLimit)
        #expect(chosen.first?.id == "c0")
        #expect(chosen.last?.id == "c19")
    }

    @Test func centresWithoutBelievableCoordinatesAreSkipped() {
        let centres = [
            RecyclingCentre(id: "none", name: "No coords", acceptedCategories: [.laptops]),
            centre("swapped", lat: 79.86, lon: 6.92, accepts: [.laptops]),
            centre("ok", lat: 6.92, lon: 79.86, accepts: [.laptops])
        ]
        #expect(GeofencePlanner.select(centres: centres, categories: [.laptops], near: nil).map(\.id) == ["ok"])
    }

    @Test func onlySavedAndPlannedItemsNeedACentre() {
        let records = [item(.laptops, status: .saved), item(.printers, status: .planned),
                       item(.cameras, status: .recycled)]
        #expect(GeofencePlanner.categories(of: records) == [.laptops, .printers])
    }
}

// MARK: - View model

@MainActor
struct GeofenceViewModelTests {
    private struct Rig {
        let viewModel: GeofenceViewModel
        let service: FakeGeofenceService
        let notifier: FakeNotifier
        let store: FakeStore
        let items: FakeItems
        let clock: Clock
    }

    private final class Clock { var date = Date(timeIntervalSince1970: 1_000_000) }

    private func makeRig(items records: [ItemRecord]? = nil, centres: [RecyclingCentre]? = nil) -> Rig {
        let service = FakeGeofenceService()
        let notifier = FakeNotifier()
        let store = FakeStore()
        let items = FakeItems(records ?? [item(.mobilePhones)])
        let clock = Clock()
        let catalog = FakeCatalog(centres: centres ?? [
            centre("a", lat: 6.92, lon: 79.86, accepts: [.mobilePhones, .laptops]),
            centre("b", lat: 7.29, lon: 80.63, accepts: [.televisions])
        ])
        let viewModel = GeofenceViewModel(service: service, notifier: notifier, store: store, items: items,
                                          catalog: catalog, location: FakeLocation(), ownerUID: "u1",
                                          now: { clock.date }, cooldown: GeofenceViewModel.defaultCooldown)
        return Rig(viewModel: viewModel, service: service, notifier: notifier, store: store, items: items, clock: clock)
    }

    @Test func turningOnAsksForAlwaysAccessAndWatchesUsefulCentres() {
        let rig = makeRig()
        rig.viewModel.setEnabled(true)
        #expect(rig.service.alwaysRequests == 1)
        #expect(rig.service.monitored == ["a"])
        #expect(rig.viewModel.state == .active(centres: 1))
        #expect(rig.store.isEnabled)
    }

    @Test func turningOffStopsMonitoring() {
        let rig = makeRig()
        rig.viewModel.setEnabled(true)
        rig.viewModel.setEnabled(false)
        #expect(rig.service.monitored.isEmpty)
        #expect(rig.viewModel.state == .off)
    }

    @Test func deniedLocationShowsDeniedAndWatchesNothing() {
        let rig = makeRig()
        rig.service.authorization = .denied
        rig.viewModel.setEnabled(true)
        #expect(rig.viewModel.state == .denied)
        #expect(rig.service.monitored.isEmpty)
    }

    @Test func whenInUseOnlyAsksForAlwaysInSettings() {
        let rig = makeRig()
        rig.service.authorization = .authorizedWhenInUse
        rig.viewModel.setEnabled(true)
        #expect(rig.viewModel.state == .needsAlways)
    }

    @Test func noItemsMeansNoRegions() {
        let rig = makeRig(items: [])
        rig.viewModel.setEnabled(true)
        #expect(rig.viewModel.state == .noRelevantCentres)
    }

    @Test func enteringACentreSendsOneAlertWithTheMatchingCategories() async {
        let rig = makeRig(items: [item(.mobilePhones), item(.laptops), item(.printers)])
        rig.viewModel.setEnabled(true)
        let sent = await rig.viewModel.handleEntry(centreID: "a")
        #expect(sent)
        #expect(rig.notifier.alerts.count == 1)
        #expect(rig.notifier.alerts[0].name == "Centre a")
        #expect(rig.notifier.alerts[0].categories == [.mobilePhones, .laptops])
    }

    @Test func theSameCentreDoesNotAlertAgainWithinTheCooldown() async {
        let rig = makeRig()
        rig.viewModel.setEnabled(true)
        _ = await rig.viewModel.handleEntry(centreID: "a")
        rig.clock.date.addTimeInterval(60 * 60)
        let second = await rig.viewModel.handleEntry(centreID: "a")
        #expect(!second)

        rig.clock.date.addTimeInterval(13 * 60 * 60)
        let third = await rig.viewModel.handleEntry(centreID: "a")
        #expect(third)
        #expect(rig.notifier.alerts.count == 2)
    }

    @Test func noAlertWhenTheCentreAcceptsNothingTheUserHas() async {
        let rig = makeRig()
        rig.viewModel.setEnabled(true)
        let sent = await rig.viewModel.handleEntry(centreID: "b")
        #expect(!sent)
        #expect(rig.notifier.alerts.isEmpty)
    }

    @Test func noAlertWhenSwitchedOff() async {
        let rig = makeRig()
        let sent = await rig.viewModel.handleEntry(centreID: "a")
        #expect(!sent)
    }

    @Test func theServiceCallbackReachesTheViewModel() async {
        let rig = makeRig()
        rig.viewModel.setEnabled(true)
        rig.service.onEnter?("a")
        try? await Task.sleep(for: .milliseconds(100))
        #expect(rig.notifier.alerts.count == 1)
    }
}
