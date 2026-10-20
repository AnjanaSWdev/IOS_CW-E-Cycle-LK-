//
//  ItemsViewModelTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-20.
//

import Foundation
import Testing
@testable import ecyclelk   // change to your module name if different

@MainActor
private final class FakeItemsService: ItemsServiceProtocol {
    var stored: [ItemRecord] = []
    var shouldFail = false

    func fetchItems(ownerUID: String) throws -> [ItemRecord] {
        if shouldFail { throw ItemsServiceError.notFound }
        return stored
    }

    @discardableResult
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord {
        if shouldFail { throw ItemsServiceError.notFound }
        let record = ItemRecord(
            id: UUID(), name: draft.trimmedName, category: draft.category,
            condition: draft.condition, notes: draft.trimmedNotes,
            weightKg: draft.weightKg, dateAdded: Date(), status: .saved
        )
        stored.insert(record, at: 0)
        return record
    }

    func updateItem(id: UUID, with draft: ItemDraft) throws {
        guard let index = stored.firstIndex(where: { $0.id == id }) else { throw ItemsServiceError.notFound }
        stored[index].name = draft.trimmedName
        stored[index].category = draft.category
    }

    func deleteItem(id: UUID) throws {
        guard stored.contains(where: { $0.id == id }) else { throw ItemsServiceError.notFound }
        stored.removeAll { $0.id == id }
    }
}

@MainActor
struct ItemsViewModelTests {
    private func makeViewModel() -> (ItemsViewModel, FakeItemsService) {
        let service = FakeItemsService()
        return (ItemsViewModel(service: service), service)
    }

    @Test func addingItemWithNameAppearsInList() {
        let (viewModel, _) = makeViewModel()
        let saved = viewModel.add(ItemDraft(name: "Old Laptop", category: .laptops))
        #expect(saved)
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.name == "Old Laptop")
    }

    @Test func blankNameIsRejected() {
        let (viewModel, _) = makeViewModel()
        let saved = viewModel.add(ItemDraft(name: "   "))
        #expect(!saved)
        #expect(viewModel.items.isEmpty)
    }

    @Test func nameIsTrimmedBeforeSaving() {
        let (viewModel, _) = makeViewModel()
        viewModel.add(ItemDraft(name: "  Power bank  ", category: .batteries))
        #expect(viewModel.items.first?.name == "Power bank")
    }

    @Test func searchIsCaseInsensitive() {
        let (viewModel, _) = makeViewModel()
        viewModel.add(ItemDraft(name: "Samsung Galaxy S9", category: .mobilePhones))
        viewModel.add(ItemDraft(name: "Dell Inspiron 15", category: .laptops))
        viewModel.searchText = "galaxy"
        #expect(viewModel.filteredItems.map(\.name) == ["Samsung Galaxy S9"])
    }

    @Test func categoryFilterOnlyKeepsThatCategory() {
        let (viewModel, _) = makeViewModel()
        viewModel.add(ItemDraft(name: "Power bank", category: .batteries))
        viewModel.add(ItemDraft(name: "Dell Inspiron 15", category: .laptops))
        viewModel.selectedCategory = .batteries
        #expect(viewModel.filteredItems.count == 1)
        #expect(viewModel.filteredItems.first?.category == .batteries)
    }

    @Test func deleteRemovesTheItem() throws {
        let (viewModel, _) = makeViewModel()
        viewModel.add(ItemDraft(name: "Old camera", category: .cameras))
        let item = try #require(viewModel.items.first)
        viewModel.delete(item)
        #expect(viewModel.items.isEmpty)
    }

    @Test func serviceFailureSetsErrorMessage() {
        let (viewModel, service) = makeViewModel()
        service.shouldFail = true
        viewModel.load()
        #expect(viewModel.errorMessage != nil)
    }
}
