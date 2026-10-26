//
//  PlanModels.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation

enum PlanType: String, CaseIterable, Identifiable {
    case dropOff
    case communityPickup

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dropOff: return "Drop-off"
        case .communityPickup: return "Community pickup"
        }
    }
}

enum PlanStatus: String, CaseIterable, Identifiable {
    case upcoming
    case completed
    case cancelled

    var id: String { rawValue }
}

/// A plain value copy of one recycling plan (same idea as ItemRecord).
struct PlanRecord: Identifiable, Hashable {
    let id: UUID
    var title: String
    var type: PlanType
    var start: Date
    var end: Date?
    var centreID: String?
    var centreName: String?
    var reminderEnabled: Bool
    var reminderMinutesBefore: Int
    var status: PlanStatus
    var completedDate: Date?
    var itemIDs: [UUID]
    var itemNames: [String]

    var itemCount: Int { itemIDs.count }
}

/// What the "New plan" form collects.
struct PlanDraft: Equatable {
    var type: PlanType = .dropOff
    var itemIDs: Set<UUID> = []
    var centreID: String?
    var centreName: String?
    var start: Date
    var reminderEnabled = true
    /// Default is one day before, as in the prototype.
    var reminderMinutesBefore = 1440

    enum Problem: LocalizedError, Equatable {
        case noItems, noCentre, startInPast, reminderInPast

        var errorDescription: String? {
            switch self {
            case .noItems: return "Choose at least one item to recycle."
            case .noCentre: return "Choose a recycling centre."
            case .startInPast: return "Pick a date and time in the future."
            case .reminderInPast: return "That reminder time has already passed. Choose a shorter reminder or a later plan."
            }
        }
    }

    var title: String {
        if type == .dropOff, let centreName { return "Drop-off at \(centreName)" }
        return type.displayName
    }

    var reminderFireDate: Date? {
        reminderEnabled ? start.addingTimeInterval(-Double(reminderMinutesBefore) * 60) : nil
    }

    /// The first thing wrong with this draft, or nil if it is fine to save.
    func firstProblem(now: Date = Date()) -> Problem? {
        if itemIDs.isEmpty { return .noItems }
        if type == .dropOff && centreID == nil { return .noCentre }
        if start <= now { return .startInPast }
        if let fireDate = reminderFireDate, fireDate <= now { return .reminderInPast }
        return nil
    }
}
