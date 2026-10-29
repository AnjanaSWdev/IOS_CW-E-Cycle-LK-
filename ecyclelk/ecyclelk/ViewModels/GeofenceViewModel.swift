//
//  GeofenceViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import Foundation
import CoreLocation
import Observation

/// "Centre alerts": when you come near a recycling centre that accepts something you own,
/// the app sends a notification. Uses geofences (CLCircularRegion) around the nearest centres.
@MainActor
@Observable
final class GeofenceViewModel {

    enum State: Equatable {
        case off
        /// Switched on, but location is not "Always", so alerts only work while the app is open.
        case needsAlways
        case denied
        case noRelevantCentres
        case active(centres: Int)
    }

    private(set) var isEnabled: Bool
    private(set) var state: State = .off

    private let service: GeofenceMonitoring
    private let notifier: CentreAlertNotifying
    private let store: GeofenceStoring
    private let items: ItemsServiceProtocol
    private let catalog: CentresCatalog
    private let location: LocationProviding
    private let ownerUID: String
    private let now: () -> Date
    private let cooldown: TimeInterval
    private var centres: [RecyclingCentre] = []

    init(service: GeofenceMonitoring,
         notifier: CentreAlertNotifying,
         store: GeofenceStoring,
         items: ItemsServiceProtocol,
         catalog: CentresCatalog,
         location: LocationProviding,
         ownerUID: String,
         now: @escaping () -> Date,
         cooldown: TimeInterval) {
        self.service = service
        self.notifier = notifier
        self.store = store
        self.items = items
        self.catalog = catalog
        self.location = location
        self.ownerUID = ownerUID
        self.now = now
        self.cooldown = cooldown
        self.isEnabled = store.isEnabled
        self.service.onEnter = { [weak self] centreID in
            Task { await self?.handleEntry(centreID: centreID) }
        }
    }

    /// One alert per centre per 12 hours.
    static let defaultCooldown: TimeInterval = 12 * 60 * 60

    // MARK: - Switch

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        store.isEnabled = enabled
        if enabled {
            service.requestAlwaysAccess()
            refresh()
        } else {
            service.stopAll()
            state = .off
        }
    }

    /// Re-chooses which centres to watch. Call on launch, when items change and when the position changes a lot.
    func refresh() {
        guard isEnabled else { state = .off; return }

        switch service.authorization {
        case .denied, .restricted:
            service.stopAll()
            state = .denied
            return
        case .notDetermined:
            state = .needsAlways
            return
        default:
            break
        }

        loadCentresIfNeeded()
        let records = (try? items.fetchItems(ownerUID: ownerUID)) ?? []
        let categories = GeofencePlanner.categories(of: records)
        let chosen = GeofencePlanner.select(centres: centres, categories: categories, near: location.location)

        service.startMonitoring(chosen, radius: GeofencePlanner.radiusMeters)

        if chosen.isEmpty {
            state = .noRelevantCentres
        } else if service.authorization == .authorizedAlways {
            state = .active(centres: chosen.count)
        } else {
            state = .needsAlways
        }
    }

    // MARK: - Entering a centre

    /// The phone entered a centre's region. Sends an alert if the person has something it accepts.
    @discardableResult
    func handleEntry(centreID: String) async -> Bool {
        guard isEnabled else { return false }
        loadCentresIfNeeded()
        guard let centre = centres.first(where: { $0.id == centreID }) else { return false }

        let records = (try? items.fetchItems(ownerUID: ownerUID)) ?? []
        let matching = GeofencePlanner.matches(for: centre, in: GeofencePlanner.categories(of: records))
        guard !matching.isEmpty else { return false }

        let current = now()
        if let last = store.lastAlert(for: centreID), current.timeIntervalSince(last) < cooldown { return false }
        store.setLastAlert(current, for: centreID)

        await notifier.sendAlert(centreID: centre.id, centreName: centre.name, categories: matching)
        return true
    }

    private func loadCentresIfNeeded() {
        guard centres.isEmpty else { return }
        centres = (try? catalog.loadCentres()) ?? []
    }
}
