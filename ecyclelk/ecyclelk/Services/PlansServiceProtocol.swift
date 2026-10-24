//
//  PlansServiceProtocol.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation

@MainActor
protocol PlansServiceProtocol {
    func fetchPlans(ownerUID: String) throws -> [PlanRecord]
    /// Saves the plan and marks its items as "planned".
    @discardableResult
    func createPlan(_ draft: PlanDraft, ownerUID: String) throws -> PlanRecord
    /// Marks the plan completed and its items as recycled.
    func completePlan(id: UUID, on date: Date) throws
    /// Marks the plan cancelled and frees its items again.
    func cancelPlan(id: UUID) throws
}

enum PlansServiceError: LocalizedError {
    case itemNotFound, planNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound: return "One of the selected items could not be found."
        case .planNotFound: return "That plan could not be found."
        }
    }
}
