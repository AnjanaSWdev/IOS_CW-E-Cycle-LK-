//
//  CoreDataPlansService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

internal import CoreData
import Foundation

@MainActor
final class CoreDataPlansService: PlansServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchPlans(ownerUID: String) throws -> [PlanRecord] {
        let request = NSFetchRequest<RecyclingPlan>(entityName: "RecyclingPlan")
        request.predicate = NSPredicate(format: "ownerUID == %@", ownerUID)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RecyclingPlan.scheduledStart, ascending: true)]
        return try context.fetch(request).compactMap(makeRecord)
    }

    @discardableResult
    func createPlan(_ draft: PlanDraft, ownerUID: String) throws -> PlanRecord {
        let items = try fetchItems(ids: draft.itemIDs, ownerUID: ownerUID)
        guard items.count == draft.itemIDs.count else { throw PlansServiceError.itemNotFound }

        let plan = RecyclingPlan(context: context)
        let id = UUID()
        plan.id = id
        plan.title = draft.title
        plan.planType = draft.type.rawValue
        plan.scheduledStart = draft.start
        plan.centreID = draft.centreID
        plan.centreName = draft.centreName
        plan.reminderEnabled = draft.reminderEnabled
        plan.reminderMinutesBefore = Int32(draft.reminderMinutesBefore)
        // The reminder uses the plan's id as its notification id, so it can be cancelled later.
        plan.notificationID = draft.reminderEnabled ? id.uuidString : nil
        plan.status = PlanStatus.upcoming.rawValue
        plan.ownerUID = ownerUID

        for item in items {
            item.status = ItemStatus.planned.rawValue
            item.plan = plan
        }
        try saveContext()

        guard let record = makeRecord(plan) else { throw PlansServiceError.planNotFound }
        return record
    }

    func completePlan(id: UUID, on date: Date) throws {
        let plan = try fetchPlan(id: id)
        plan.status = PlanStatus.completed.rawValue
        plan.completedDate = date
        for item in planItems(plan) {
            item.status = ItemStatus.recycled.rawValue
            item.recycledDate = date
        }
        try saveContext()
    }

    func cancelPlan(id: UUID) throws {
        let plan = try fetchPlan(id: id)
        plan.status = PlanStatus.cancelled.rawValue
        for item in planItems(plan) {
            item.status = ItemStatus.saved.rawValue
            item.plan = nil
        }
        try saveContext()
    }

    // MARK: - Helpers

    private func fetchPlan(id: UUID) throws -> RecyclingPlan {
        let request = NSFetchRequest<RecyclingPlan>(entityName: "RecyclingPlan")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let plan = try context.fetch(request).first else { throw PlansServiceError.planNotFound }
        return plan
    }

    private func fetchItems(ids: Set<UUID>, ownerUID: String) throws -> [EwasteItem] {
        let request = NSFetchRequest<EwasteItem>(entityName: "EwasteItem")
        request.predicate = NSPredicate(format: "ownerUID == %@ AND id IN %@", ownerUID, Array(ids) as NSArray)
        return try context.fetch(request)
    }

    private func planItems(_ plan: RecyclingPlan) -> [EwasteItem] {
        Array((plan.items as? Set<EwasteItem>) ?? [])
    }

    private func saveContext() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func makeRecord(_ plan: RecyclingPlan) -> PlanRecord? {
        guard let id = plan.id as UUID? else { return nil }
        let items = planItems(plan).sorted {
            (($0.name as String?) ?? "") < (($1.name as String?) ?? "")
        }
        return PlanRecord(
            id: id,
            title: (plan.title as String?) ?? "Recycling plan",
            type: PlanType(rawValue: (plan.planType as String?) ?? "") ?? .dropOff,
            start: (plan.scheduledStart as Date?) ?? Date(),
            end: plan.scheduledEnd,
            centreID: plan.centreID,
            centreName: plan.centreName,
            reminderEnabled: plan.reminderEnabled,
            reminderMinutesBefore: Int(plan.reminderMinutesBefore),
            status: PlanStatus(rawValue: (plan.status as String?) ?? "") ?? .upcoming,
            completedDate: plan.completedDate,
            itemIDs: items.compactMap { $0.id as UUID? },
            itemNames: items.map { ($0.name as String?) ?? "" }
        )
    }
}
