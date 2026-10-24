//
//  PlansViewModelTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Testing
@testable import ecyclelk   // your module name

@MainActor
private final class FakePlansService: PlansServiceProtocol {
    var stored: [PlanRecord] = []

    func fetchPlans(ownerUID: String) throws -> [PlanRecord] { stored }

    func createPlan(_ draft: PlanDraft, ownerUID: String) throws -> PlanRecord {
        let record = PlanRecord(
            id: UUID(), title: draft.title, type: draft.type, start: draft.start, end: nil,
            centreID: draft.centreID, centreName: draft.centreName,
            reminderEnabled: draft.reminderEnabled, reminderMinutesBefore: draft.reminderMinutesBefore,
            status: .upcoming, completedDate: nil, itemIDs: Array(draft.itemIDs), itemNames: []
        )
        stored.append(record)
        return record
    }

    func completePlan(id: UUID, on date: Date) throws {
        guard let index = stored.firstIndex(where: { $0.id == id }) else { throw PlansServiceError.planNotFound }
        stored[index].status = .completed
        stored[index].completedDate = date
    }

    func cancelPlan(id: UUID) throws {
        guard let index = stored.firstIndex(where: { $0.id == id }) else { throw PlansServiceError.planNotFound }
        stored[index].status = .cancelled
    }
}

@MainActor
private final class FakeItemsForPlans: ItemsServiceProtocol {
    var items: [ItemRecord] = []
    func fetchItems(ownerUID: String) throws -> [ItemRecord] { items }
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord { throw ItemsServiceError.notFound }
    func updateItem(id: UUID, with draft: ItemDraft) throws {}
    func deleteItem(id: UUID) throws {}
}

@MainActor
private final class FakeReminders: ReminderSchedulerProtocol {
    var authorized = true
    private(set) var scheduledIDs: [String] = []
    private(set) var cancelledIDs: [String] = []

    func requestAuthorization() async -> Bool { authorized }
    func scheduleReminder(id: String, title: String, body: String, at fireDate: Date) async throws {
        scheduledIDs.append(id)
    }
    func cancelReminder(id: String) { cancelledIDs.append(id) }
}

@MainActor
struct PlansViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let itemID = UUID()

    private func makeViewModel() -> (PlansViewModel, FakePlansService, FakeReminders, FakeItemsForPlans) {
        let plans = FakePlansService()
        let items = FakeItemsForPlans()
        let reminders = FakeReminders()
        let now = self.now
        let viewModel = PlansViewModel(plansService: plans, itemsService: items,
                                       reminders: reminders, now: { now })
        return (viewModel, plans, reminders, items)
    }

    private func validDraft() -> PlanDraft {
        PlanDraft(itemIDs: [itemID], centreID: "ekunu-01", centreName: "eKunu Collection Point - Kandy",
                  start: now.addingTimeInterval(3 * 86_400))
    }

    @Test func creatingPlanSavesItAndSchedulesReminder() async {
        let (viewModel, plans, reminders, _) = makeViewModel()
        let saved = await viewModel.createPlan(validDraft())
        #expect(saved)
        #expect(plans.stored.count == 1)
        #expect(reminders.scheduledIDs.count == 1)
    }

    @Test func planWithoutItemsIsRejected() async {
        let (viewModel, plans, _, _) = makeViewModel()
        var draft = validDraft()
        draft.itemIDs = []
        let saved = await viewModel.createPlan(draft)
        #expect(!saved)
        #expect(plans.stored.isEmpty)
        #expect(viewModel.errorMessage == PlanDraft.Problem.noItems.errorDescription)
    }

    @Test func dropOffNeedsACentre() {
        var draft = validDraft()
        draft.centreID = nil
        #expect(draft.firstProblem(now: now) == .noCentre)
    }

    @Test func startInThePastIsRejected() {
        var draft = validDraft()
        draft.start = now.addingTimeInterval(-60)
        #expect(draft.firstProblem(now: now) == .startInPast)
    }

    @Test func reminderTimeAlreadyPassedIsRejected() {
        var draft = validDraft()
        draft.start = now.addingTimeInterval(3_600)      // plan is in 1 hour
        draft.reminderMinutesBefore = 1440               // reminder would be a day before
        #expect(draft.firstProblem(now: now) == .reminderInPast)
    }

    @Test func deniedPermissionStillSavesThePlan() async {
        let (viewModel, plans, reminders, _) = makeViewModel()
        reminders.authorized = false
        let saved = await viewModel.createPlan(validDraft())
        #expect(saved)
        #expect(plans.stored.count == 1)
        #expect(viewModel.remindersDenied)
        #expect(reminders.scheduledIDs.isEmpty)
    }

    @Test func noReminderWhenTurnedOff() async {
        let (viewModel, _, reminders, _) = makeViewModel()
        var draft = validDraft()
        draft.reminderEnabled = false
        await viewModel.createPlan(draft)
        #expect(reminders.scheduledIDs.isEmpty)
    }

    @Test func completingAPlanCancelsItsReminderAndMovesItToCompleted() async throws {
        let (viewModel, _, reminders, _) = makeViewModel()
        await viewModel.createPlan(validDraft())
        let plan = try #require(viewModel.upcomingPlans.first)
        viewModel.completePlan(plan)
        #expect(viewModel.upcomingPlans.isEmpty)
        #expect(viewModel.completedPlans.count == 1)
        #expect(reminders.cancelledIDs == [plan.id.uuidString])
    }

    @Test func onlySavedItemsCanBePlanned() {
        let (viewModel, _, _, items) = makeViewModel()
        items.items = [
            ItemRecord(id: UUID(), name: "Phone", category: .mobilePhones, condition: .working, notes: "",
                       weightKg: 0.2, dateAdded: now, status: .saved),
            ItemRecord(id: UUID(), name: "Laptop", category: .laptops, condition: .working, notes: "",
                       weightKg: 2, dateAdded: now, status: .planned)
        ]
        viewModel.load()
        #expect(viewModel.availableItems.map(\.name) == ["Phone"])
    }
    
    @Test func reminderLeadLabelsAreReadable() {
        #expect(ReminderLead.label(forMinutes: 1440) == "1 day before")
        #expect(ReminderLead.label(forMinutes: 90) == "90 minutes before")
    }
}
