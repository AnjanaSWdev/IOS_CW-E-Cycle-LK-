//
//  GeoFencePlanner.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import Foundation
import CoreLocation

// Decides WHICH centres get a geofence. iOS only allows 20 monitored regions per app, so we pick
// the nearest centres that accept something the person actually has. Pure logic, easy to test.

enum GeofencePlanner {
    
    // iOS limit for region monitoring.
    static let regionLimit = 20
    // How close (metres) you must get to a centre to trigger the alert.
    static let radiusMeters: CLLocationDistance = 500

    // Categories of items that still need recycling (saved or planned). Items listed on the
    // community board, rehomed or recycled do not need a centre.
    static func categories(of items: [ItemRecord]) -> Set<ItemCategory> {
        Set(items.filter { $0.status == .saved || $0.status == .planned }.map(\.category))
    }

    // Categories in `categories` that this centre accepts, in a stable order.
    static func matches(for centre: RecyclingCentre, in categories: Set<ItemCategory>) -> [ItemCategory] {
        ItemCategory.allCases.filter { categories.contains($0) && centre.accepts($0) }
    }

    // Up to `limit` centres to monitor: only useful ones (they accept one of the person's items and
    // have believable coordinates), nearest first. Without a known position, alphabetical.
    static func select(centres: [RecyclingCentre],
                       categories: Set<ItemCategory>,
                       near userLocation: CLLocation?,
                       limit: Int = regionLimit) -> [RecyclingCentre] {
        let useful = centres.filter { centre in
            centre.hasPlausibleSriLankanCoordinate && !matches(for: centre, in: categories).isEmpty
        }
        let sorted = useful.sorted { lhs, rhs in
            if let userLocation, let a = lhs.location, let b = rhs.location {
                let da = userLocation.distance(from: a)
                let db = userLocation.distance(from: b)
                if da != db { return da < db }
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return Array(sorted.prefix(max(0, limit)))
    }
}
