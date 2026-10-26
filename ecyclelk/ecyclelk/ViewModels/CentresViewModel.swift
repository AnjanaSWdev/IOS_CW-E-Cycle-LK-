//
//  CentresViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation
import CoreLocation
import Observation
 
/// Drives the Centres tab: loading, search, category filter, distance and sorting.
@MainActor
@Observable
final class CentresViewModel {
 
    enum DisplayMode: String, CaseIterable, Identifiable {
        case list = "List"
        case map = "Map"
        var id: String { rawValue }
    }
 
    enum LocationState: Equatable {
        case notAsked, denied, locating, available
    }
 
    /// A centre plus its distance from the user (nil when the position or coordinates are unknown).
    struct Row: Identifiable, Equatable {
        let centre: RecyclingCentre
        let distanceMeters: Double?
        var id: String { centre.id }
    }
 
    private(set) var centres: [RecyclingCentre] = []
    var errorMessage: String?
    var searchText = ""
    var categoryFilter: ItemCategory?
    var publicDropOffOnly = false
    var displayMode: DisplayMode = .list
 
    private let catalog: CentresCatalog
    private let locationProvider: LocationProviding
 
    init(catalog: CentresCatalog, location: LocationProviding) {
        self.catalog = catalog
        self.locationProvider = location
    }
 
    // MARK: Loading
 
    func load() {
        guard centres.isEmpty else { return }
        do {
            centres = try catalog.loadCentres()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
 
    // MARK: Location
 
    var locationState: LocationState {
        switch locationProvider.authorization {
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        default: return locationProvider.location == nil ? .locating : .available
        }
    }
 
    func requestLocation() { locationProvider.requestAccess() }
    func refreshLocation() { locationProvider.refresh() }
 
    func distance(to centre: RecyclingCentre) -> Double? {
        guard let user = locationProvider.location, let target = centre.location else { return nil }
        return user.distance(from: target)
    }
 
    // MARK: What the screen shows
 
    var visibleRows: [Row] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let rows = centres
            .filter { centre in
                if let categoryFilter, !centre.accepts(categoryFilter) { return false }
                if publicDropOffOnly, centre.kind != .ekunuPublicDropoff { return false }
                if !query.isEmpty {
                    let haystack = [centre.name, centre.address, centre.district].joined(separator: " ")
                    if !haystack.localizedCaseInsensitiveContains(query) { return false }
                }
                return true
            }
            .map { Row(centre: $0, distanceMeters: distance(to: $0)) }
 
        return rows.sorted { lhs, rhs in
            switch (lhs.distanceMeters, rhs.distanceMeters) {
            case let (a?, b?) where a != b: return a < b
            case (_?, nil): return true          // centres with a distance come first
            case (nil, _?): return false
            default: return lhs.centre.name.localizedCaseInsensitiveCompare(rhs.centre.name) == .orderedAscending
            }
        }
    }
 
    var mappableRows: [Row] { visibleRows.filter { $0.centre.coordinate != nil } }
 
    var hasActiveFilters: Bool {
        categoryFilter != nil || publicDropOffOnly || !searchText.isEmpty
    }
 
    func clearFilters() {
        categoryFilter = nil
        publicDropOffOnly = false
        searchText = ""
    }
 
    static func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int((meters / 10).rounded() * 10)) m"
        }
        let kilometres = meters / 1000
        return kilometres < 100 ? String(format: "%.1f km", kilometres) : "\(Int(kilometres.rounded())) km"
    }
}
