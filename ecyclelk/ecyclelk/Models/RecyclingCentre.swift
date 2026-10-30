//
//  RecyclingCentre.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation
import CoreLocation
 
// Who runs the place. Read from the "type" column of centres.csv.
enum CentreKind: String, Hashable {
    case ekunuPublicDropoff = "ekunu_public_dropoff"
    case ceaLicensedCollector = "cea_licensed_collector"
    case other
 
    var displayName: String {
        switch self {
        case .ekunuPublicDropoff: return "Public drop-off"
        case .ceaLicensedCollector: return "Licensed collector"
        case .other: return "Recycling centre"
        }
    }
}
 
// One recycling centre, as read from centres.csv.
struct RecyclingCentre: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: CentreKind
    let address: String
    let district: String
    let latitude: Double?
    let longitude: Double?
    let phone: String
    let openingHours: String
    let acceptedCategories: Set<ItemCategory>
    // True when the centre should be phoned first (mostly business-focused collectors).
    let needsConfirmation: Bool
    let source: String
    let notes: String
 
    init(id: String,
         name: String,
         kind: CentreKind = .ekunuPublicDropoff,
         address: String = "",
         district: String = "",
         latitude: Double? = nil,
         longitude: Double? = nil,
         phone: String = "",
         openingHours: String = "",
         acceptedCategories: Set<ItemCategory> = [],
         needsConfirmation: Bool = false,
         source: String = "",
         notes: String = "") {
        self.id = id
        self.name = name
        self.kind = kind
        self.address = address
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
        self.phone = phone
        self.openingHours = openingHours
        self.acceptedCategories = acceptedCategories
        self.needsConfirmation = needsConfirmation
        self.source = source
        self.notes = notes
    }
 
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
 
    var location: CLLocation? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
 
    func accepts(_ category: ItemCategory) -> Bool {
        acceptedCategories.contains(category)
    }
 
    /// Rough bounding box of Sri Lanka. Catches blank or swapped latitude/longitude values.
    var hasPlausibleSriLankanCoordinate: Bool {
        guard let latitude, let longitude else { return false }
        return (5.8...9.95).contains(latitude) && (79.4...82.0).contains(longitude)
    }
 
    /// "tel:" link made from the first number in the phone column (it may list several).
    var phoneURL: URL? {
        guard let first = phone.split(whereSeparator: { "/,;".contains($0) }).first else { return nil }
        let dialable = first.filter { $0.isNumber || $0 == "+" }
        guard dialable.count >= 7 else { return nil }
        return URL(string: "tel:\(dialable)")
    }
}
