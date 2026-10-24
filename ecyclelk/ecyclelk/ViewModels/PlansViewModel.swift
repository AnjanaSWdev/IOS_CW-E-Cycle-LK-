//
//  PlansViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@MainActor
@Observable
final class PlansViewModel {
    private(set) var plans: [PlanRecord] = []
    /// Items that can still be put into a new plan.
    private(set) var availableItems: [ItemRecord] = []
    private(set) var centres: [CentreOption] = []
    private(set) var remindersDenied = false
    var errorMessage: String?

    private let plansService: PlansServiceProtocol
    private let itemsService: ItemsServiceProtocol
    private let reminders: ReminderSchedulerProtocol
    private let centresProvider: CentresProviding
    private let ownerUID: String
    private let now: () -> Date

    init(plansService: PlansServiceProtocol,
         itemsService: ItemsServiceProtocol,
         reminders: ReminderSchedulerProtocol,
         centresProvider: CentresProviding = SampleCentresProvider(),
         ownerUID: String = "local",
         now: @escaping () -> Date = { Date() }) {
        self.plansService = plansService
        self.itemsService = itemsService
        self.reminders = reminders
        self.centresProvider = centresProvider
        self.ownerUID = ownerUID
        self.now = now
    }

    // MARK: Derived data

    var upcomingPlans: [PlanRecord] {
        plans.filter { $0.status == .upcoming }.sorted { $0.start < $1.start }
    }

    var completedPlans: [PlanRecord] {
        plans.filter { $0.status == .completed }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }

    var nextPlan: PlanRecord? { upcomingPlans.first }

    // MARK: Actions

    func load() {
        do {
            plans = try plansService.fetchPlans(ownerUID: ownerUID)
            availableItems = try itemsService.fetchItems(ownerUID: ownerUID).filter { $0.status == .saved }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadCentres() async {
        do {
            centres = try await centresProvider.fetchCentres()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns true when the plan was saved, so the form can close.
    @discardableResult
    func createPlan(_ draft: PlanDraft) async -> Bool {
        if let problem = draft.firstProblem(now: now()) {
            errorMessage = problem.errorDescription
            return false
        }

        let plan: PlanRecord
        do {
            plan = try plansService.createPlan(draft, ownerUID: ownerUID)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        if let fireDate = draft.reminderFireDate {
            await scheduleReminder(for: plan, at: fireDate)
        }
        load()
        return true
    }

    func completePlan(_ plan: PlanRecord) {
        perform {
            try self.plansService.completePlan(id: plan.id, on: self.now())
            self.reminders.cancelReminder(id: plan.id.uuidString)
        }
    }

    func cancelPlan(_ plan: PlanRecord) {
        perform {
            try self.plansService.cancelPlan(id: plan.id)
            self.reminders.cancelReminder(id: plan.id.uuidString)
        }
    }

    // MARK: Helpers

    private func scheduleReminder(for plan: PlanRecord, at fireDate: Date) async {
        guard await reminders.requestAuthorization() else {
            remindersDenied = true          // the plan is still saved
            return
        }
        remindersDenied = false
        do {
            try await reminders.scheduleReminder(
                id: plan.id.uuidString,
                title: "E-waste drop-off reminder",
                body: Self.reminderBody(for: plan),
                at: fireDate
            )
        } catch {
            errorMessage = "The plan was saved, but its reminder couldn't be set."
        }
    }

    static func reminderBody(for plan: PlanRecord) -> String {
        let when = plan.start.formatted(date: .abbreviated, time: .shortened)
        if let centre = plan.centreName {
            return "Your e-waste drop-off at \(centre) is planned for \(when)."
        }
        return "Your e-waste \(plan.type.displayName.lowercased()) is planned for \(when)."
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
