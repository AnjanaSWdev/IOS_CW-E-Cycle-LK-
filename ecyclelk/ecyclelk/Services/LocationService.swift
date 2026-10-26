//
//  LocationService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import CoreLocation
import Observation

/// What the Centres screen needs from the phone's location. A fake stands in for it in tests.
@MainActor
protocol LocationProviding: AnyObject {
    var authorization: CLAuthorizationStatus { get }
    var location: CLLocation? { get }
    /// Asks permission the first time, otherwise just refreshes the position.
    func requestAccess()
    func refresh()
}

/// Wraps CLLocationManager. "When in use" permission only; geofencing will extend this later.
@MainActor
@Observable
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    private(set) var authorization: CLAuthorizationStatus = .notDetermined
    private(set) var location: CLLocation?

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorization = manager.authorizationStatus
    }

    func requestAccess() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            refresh()
        }
    }

    func refresh() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            self.refresh()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let latitude = last.coordinate.latitude
        let longitude = last.coordinate.longitude
        Task { @MainActor in
            self.location = CLLocation(latitude: latitude, longitude: longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep the last known position; the list still works without distances.
    }
}
