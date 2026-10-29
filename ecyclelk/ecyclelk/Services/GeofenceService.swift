//
//  GeofenceService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import CoreLocation
import Observation

/// What the app needs from region monitoring. A fake stands in for it in tests.
@MainActor
protocol GeofenceMonitoring: AnyObject {
    var authorization: CLAuthorizationStatus { get }
    /// Called with a centre id when the phone enters that centre's region.
    var onEnter: ((String) -> Void)? { get set }
    /// Asks for "Always" location (needed for alerts while the app is closed).
    func requestAlwaysAccess()
    /// Replaces the monitored regions with these centres (centres without coordinates are skipped).
    func startMonitoring(_ centres: [RecyclingCentre], radius: CLLocationDistance)
    func stopAll()
}

/// Region monitoring with CLLocationManager. iOS wakes the app when the person enters a region,
/// even if the app was closed, so no battery-hungry background tracking is needed.
@MainActor
@Observable
final class CoreLocationGeofenceService: NSObject, GeofenceMonitoring, CLLocationManagerDelegate {
    private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @ObservationIgnored var onEnter: ((String) -> Void)?
    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        authorization = manager.authorizationStatus
    }

    func requestAlwaysAccess() {
        switch manager.authorizationStatus {
        case .notDetermined, .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func startMonitoring(_ centres: [RecyclingCentre], radius: CLLocationDistance) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        let wanted = Dictionary(uniqueKeysWithValues: centres.compactMap { centre in
            centre.coordinate.map { (centre.id, $0) }
        })

        // Drop regions we no longer want.
        for region in manager.monitoredRegions where wanted[region.identifier] == nil {
            manager.stopMonitoring(for: region)
        }
        // Add new ones. Already-monitored regions are left alone.
        let existing = Set(manager.monitoredRegions.map(\.identifier))
        let safeRadius = min(radius, manager.maximumRegionMonitoringDistance)
        for (id, coordinate) in wanted where !existing.contains(id) {
            let region = CLCircularRegion(center: coordinate, radius: safeRadius, identifier: id)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
            // If the person is already inside, iOS does not send an "enter" event, so ask for the state.
            manager.requestState(for: region)
        }
    }

    func stopAll() {
        for region in manager.monitoredRegions { manager.stopMonitoring(for: region) }
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorization = status }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let id = region.identifier
        Task { @MainActor in self.onEnter?(id) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didDetermineState state: CLRegionState,
                                     for region: CLRegion) {
        guard state == .inside else { return }
        let id = region.identifier
        Task { @MainActor in self.onEnter?(id) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     monitoringDidFailFor region: CLRegion?,
                                     withError error: Error) {
        print("Geofence monitoring failed for \(region?.identifier ?? "?"): \(error)")
    }
}
