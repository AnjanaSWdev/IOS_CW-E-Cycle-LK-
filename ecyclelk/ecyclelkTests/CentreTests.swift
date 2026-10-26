//
//  CentreTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-26.
//

import Foundation
import CoreLocation
import Testing
@testable import ecyclelk

// MARK: - CSV parsing

@MainActor
struct CentreCSVParserTests {
    private let header = "id,name,type,address,district,latitude,longitude,phone,openingHours,acceptedCategories,needsConfirmation,source,notes"

    @Test func quotedFieldsKeepTheirCommasAndQuotes() {
        let csv = header + "\n" + #"a-1,"Shop, ""Main"" Branch",ekunu_public_dropoff,"No 5, Galle Road, Colombo",Colombo,6.9,79.85,0112 522 111,,mobilePhones|laptops,no,src,"note, with comma""#
        let centres = CentreCSVParser.parseCentres(from: csv)
        #expect(centres.count == 1)
        #expect(centres[0].name == #"Shop, "Main" Branch"#)
        #expect(centres[0].address == "No 5, Galle Road, Colombo")
        #expect(centres[0].notes == "note, with comma")
    }

    @Test func parsesCoordinatesCategoriesAndFlags() throws {
        let csv = header + "\n" + "c-1,Think Green,cea_licensed_collector,Addr,Colombo,6.95,79.87,0112 522 111,,mobilePhones|printers|nonsense,yes,cea,"
        let centre = try #require(CentreCSVParser.parseCentres(from: csv).first)
        #expect(centre.kind == .ceaLicensedCollector)
        #expect(centre.latitude == 6.95)
        #expect(centre.longitude == 79.87)
        #expect(centre.acceptedCategories == [.mobilePhones, .printers])   // unknown names are ignored
        #expect(centre.needsConfirmation)
        #expect(centre.hasPlausibleSriLankanCoordinate)
    }

    @Test func blankCoordinatesBecomeNil() throws {
        let csv = header + "\n" + "c-2,No Coords,ekunu_public_dropoff,Addr,Kandy,,,,,laptops,no,src,"
        let centre = try #require(CentreCSVParser.parseCentres(from: csv).first)
        #expect(centre.latitude == nil)
        #expect(centre.coordinate == nil)
        #expect(!centre.hasPlausibleSriLankanCoordinate)
    }

    @Test func swappedLatitudeAndLongitudeAreFlagged() {
        let centre = RecyclingCentre(id: "x", name: "Swapped", latitude: 79.86, longitude: 6.92)
        #expect(!centre.hasPlausibleSriLankanCoordinate)
    }

    @Test func handlesWindowsLineEndingsBlankLinesAndByteOrderMark() {
        let csv = "\u{FEFF}" + header + "\r\n" + "a,One,ekunu_public_dropoff,A,D,6.9,79.8,,,laptops,no,s,\r\n\r\n" + "b,Two,ekunu_public_dropoff,A,D,7.0,80.0,,,laptops,no,s,\r\n"
        #expect(CentreCSVParser.parseCentres(from: csv).map(\.id) == ["a", "b"])
    }

    @Test func columnOrderDoesNotMatter() throws {
        let csv = "name,id,longitude,latitude\nShuffled,s-1,80.1,7.2"
        let centre = try #require(CentreCSVParser.parseCentres(from: csv).first)
        #expect(centre.id == "s-1")
        #expect(centre.latitude == 7.2)
        #expect(centre.longitude == 80.1)
    }

    @Test func rowsMissingAnIDOrNameAreSkipped() {
        let csv = "id,name\n,No id\nok,Has both\nno-name,"
        #expect(CentreCSVParser.parseCentres(from: csv).map(\.id) == ["ok"])
    }

    @Test func phoneLinkUsesTheFirstNumberOnly() {
        #expect(RecyclingCentre(id: "p", name: "P", phone: "0112 522 111").phoneURL?.absoluteString == "tel:0112522111")
        #expect(RecyclingCentre(id: "p", name: "P", phone: "+94 11 234 5678 / 0771234567").phoneURL?.absoluteString == "tel:+94112345678")
        #expect(RecyclingCentre(id: "p", name: "P", phone: "").phoneURL == nil)
    }
}

// MARK: - View model

@MainActor
private final class FakeCatalog: CentresCatalog {
    var centres: [RecyclingCentre]
    var error: Error?
    init(_ centres: [RecyclingCentre], error: Error? = nil) {
        self.centres = centres
        self.error = error
    }
    func loadCentres() throws -> [RecyclingCentre] {
        if let error { throw error }
        return centres
    }
}

@MainActor
private final class FakeLocation: LocationProviding {
    var authorization: CLAuthorizationStatus
    var location: CLLocation?
    private(set) var accessRequests = 0
    init(authorization: CLAuthorizationStatus = .notDetermined, location: CLLocation? = nil) {
        self.authorization = authorization
        self.location = location
    }
    func requestAccess() { accessRequests += 1 }
    func refresh() {}
}

@MainActor
struct CentresViewModelTests {
    private let colombo = CLLocation(latitude: 6.9271, longitude: 79.8612)

    private var sample: [RecyclingCentre] {
        [
            RecyclingCentre(id: "jaffna", name: "eKunu Jaffna", address: "Stanley Road, Jaffna", district: "Jaffna",
                            latitude: 9.66, longitude: 80.01, acceptedCategories: [.laptops]),
            RecyclingCentre(id: "colombo", name: "eKunu Modern", address: "R A De Mel Mawatha, Colombo 03", district: "Colombo",
                            latitude: 6.92, longitude: 79.85, acceptedCategories: [.laptops, .printers]),
            RecyclingCentre(id: "kandy", name: "eKunu Kandy", address: "D S Senanayake Street, Kandy", district: "Kandy",
                            latitude: 7.29, longitude: 80.63, acceptedCategories: [.laptops, .batteries]),
            RecyclingCentre(id: "nocoords", name: "Think Green", kind: .ceaLicensedCollector, address: "Colombo 15",
                            district: "Colombo", acceptedCategories: [.laptops, .printers], needsConfirmation: true)
        ]
    }

    private func makeViewModel(location: LocationProviding? = nil,
                               centres: [RecyclingCentre]? = nil) -> CentresViewModel {
        let location = location ?? FakeLocation()
        let viewModel = CentresViewModel(catalog: FakeCatalog(centres ?? sample), location: location)
        viewModel.load()
        return viewModel
    }

    @Test func withoutLocationCentresAreSortedByName() {
        let viewModel = makeViewModel()
        #expect(viewModel.visibleRows.map(\.centre.name) == ["eKunu Jaffna", "eKunu Kandy", "eKunu Modern", "Think Green"])
        #expect(viewModel.visibleRows.allSatisfy { $0.distanceMeters == nil })
    }

    @Test func withLocationNearestComesFirstAndMissingCoordinatesLast() {
        let viewModel = makeViewModel(location: FakeLocation(authorization: .authorizedWhenInUse, location: colombo))
        #expect(viewModel.visibleRows.map(\.id) == ["colombo", "kandy", "jaffna", "nocoords"])
        #expect(viewModel.visibleRows.last?.distanceMeters == nil)
    }

    @Test func categoryFilterKeepsOnlyCentresThatAcceptIt() {
        let viewModel = makeViewModel()
        viewModel.categoryFilter = .printers
        #expect(Set(viewModel.visibleRows.map(\.id)) == ["colombo", "nocoords"])
    }

    @Test func searchMatchesNameAddressAndDistrictIgnoringCase() {
        let viewModel = makeViewModel()
        viewModel.searchText = "kANDy"
        #expect(viewModel.visibleRows.map(\.id) == ["kandy"])
        viewModel.searchText = "colombo"
        #expect(Set(viewModel.visibleRows.map(\.id)) == ["colombo", "nocoords"])
    }

    @Test func publicDropOffToggleHidesLicensedCollectors() {
        let viewModel = makeViewModel()
        viewModel.publicDropOffOnly = true
        #expect(!viewModel.visibleRows.map(\.id).contains("nocoords"))
    }

    @Test func clearFiltersResetsEverything() {
        let viewModel = makeViewModel()
        viewModel.categoryFilter = .batteries
        viewModel.publicDropOffOnly = true
        viewModel.searchText = "x"
        #expect(viewModel.hasActiveFilters)
        viewModel.clearFilters()
        #expect(!viewModel.hasActiveFilters)
        #expect(viewModel.visibleRows.count == 4)
    }

    @Test func mapOnlyGetsCentresWithCoordinates() {
        let viewModel = makeViewModel()
        #expect(viewModel.mappableRows.count == 3)
    }

    @Test func locationStateFollowsPermission() {
        #expect(makeViewModel(location: FakeLocation(authorization: .notDetermined)).locationState == .notAsked)
        #expect(makeViewModel(location: FakeLocation(authorization: .denied)).locationState == .denied)
        #expect(makeViewModel(location: FakeLocation(authorization: .restricted)).locationState == .denied)
        #expect(makeViewModel(location: FakeLocation(authorization: .authorizedWhenInUse)).locationState == .locating)
        #expect(makeViewModel(location: FakeLocation(authorization: .authorizedWhenInUse, location: colombo)).locationState == .available)
    }

    @Test func requestLocationAsksTheLocationService() {
        let fake = FakeLocation()
        makeViewModel(location: fake).requestLocation()
        #expect(fake.accessRequests == 1)
    }

    @Test func loadFailureShowsAMessage() {
        let viewModel = CentresViewModel(catalog: FakeCatalog([], error: CentresCatalogError.fileMissing),
                                         location: FakeLocation())
        viewModel.load()
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.visibleRows.isEmpty)
    }

    @Test func distanceTextIsReadable() {
        #expect(CentresViewModel.distanceText(450) == "450 m")
        #expect(CentresViewModel.distanceText(3249) == "3.2 km")
        #expect(CentresViewModel.distanceText(120_400) == "120 km")
    }
}

