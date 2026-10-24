//
//  ReminderLead.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation

/// The "remind me ... before" choices. The raw value is the number of minutes.
enum ReminderLead: Int, CaseIterable, Identifiable {
    case oneHour = 60
    case threeHours = 180
    case oneDay = 1440
    case twoDays = 2880

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: return "1 hour before"
        case .threeHours: return "3 hours before"
        case .oneDay: return "1 day before"
        case .twoDays: return "2 days before"
        }
    }

    static func label(forMinutes minutes: Int) -> String {
        ReminderLead(rawValue: minutes)?.displayName ?? "\(minutes) minutes before"
    }
}
