//
//  EwasteEnums.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-18.
//

import Foundation

// MARK: - Item Category

enum ItemCategory: String, CaseIterable, Identifiable {
    case mobilePhones = "mobilePhones"
    case laptops = "laptops"
    case batteries = "batteries"
    case monitors = "monitors"
    case printers = "printers"
    case televisions = "televisions"
    case cameras = "cameras"
    case electronicAccessories = "electronicAccessories"

    /// Human-readable name displayed in the UI.
    var displayName: String {
        switch self {
        case .mobilePhones:
            return "Mobile phones"
        case .laptops:
            return "Laptops"
        case .batteries:
            return "Batteries"
        case .monitors:
            return "Monitors"
        case .printers:
            return "Printers"
        case .televisions:
            return "Televisions"
        case .cameras:
            return "Cameras"
        case .electronicAccessories:
            return "Electronic accessories"
        }
    }

    /// Estimated default weight in kilograms.
    var defaultWeight: Double {
        switch self {
        case .mobilePhones:
            return 0.2
        case .laptops:
            return 2.0
        case .batteries:
            return 0.1
        case .monitors:
            return 4.0
        case .printers:
            return 6.0
        case .televisions:
            return 8.0
        case .cameras:
            return 0.5
        case .electronicAccessories:
            return 0.2
        }
    }

    /// Supports use in SwiftUI lists and ForEach.
    var id: String {
        rawValue
    }
}

// MARK: - Item Condition

enum ItemCondition: String, CaseIterable, Identifiable {
    case working = "working"
    case damaged = "damaged"
    case notWorking = "notWorking"

    /// Human-readable name displayed in the UI.
    var displayName: String {
        switch self {
        case .working:
            return "Working"
        case .damaged:
            return "Damaged"
        case .notWorking:
            return "Not working"
        }
    }

    var id: String {
        rawValue
    }
}

// MARK: - Item Status

enum ItemStatus: String, CaseIterable, Identifiable {
    case saved = "saved"
    case planned = "planned"
    case recycled = "recycled"

    /// Human-readable name displayed in the UI.
    var displayName: String {
        switch self {
        case .saved:
            return "Saved"
        case .planned:
            return "Planned"
        case .recycled:
            return "Recycled"
        }
    }

    var id: String {
        rawValue
    }
}

