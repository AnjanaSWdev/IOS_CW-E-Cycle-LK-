//
//  ItemsViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import Foundation
import Observation

@MainActor
@Observable
final class ItemsViewModel {
    // MARK: State the views read

    private(set) var items: [ItemRecord] = []
    var searchText = ""
    /// `nil` means the "All" chip is selected.
    var selectedCategory: ItemCategory?
    var errorMessage: String?

    // MARK: Dependencies

    private let service: ItemsServiceProtocol
    private let ownerUID: String

    /// - Parameter ownerUID: use "local" until Firebase sign-in exists
    ///   (Thu 22 Oct), then pass the signed-in user's uid.
    init(service: ItemsServiceProtocol, ownerUID: String = "local") {
        self.service = service
        self.ownerUID = ownerUID
    }

    // MARK: Derived data

    /// Items after the category chip and the search text are applied.
    var filteredItems: [ItemRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesSearch = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || item.category.displayName.localizedCaseInsensitiveContains(query)
            return matchesCategory && matchesSearch
        }
    }

    var hasNoItemsAtAll: Bool { items.isEmpty }

    // MARK: Actions

    func load() {
        perform { self.items = try self.service.fetchItems(ownerUID: self.ownerUID) }
    }

    /// Returns `true` when the item was saved, so the form knows it can close.
    @discardableResult
    func add(_ draft: ItemDraft) -> Bool {
        guard draft.isValid else { return false }
        return perform {
            try self.service.addItem(draft, ownerUID: self.ownerUID)
            self.items = try self.service.fetchItems(ownerUID: self.ownerUID)
        }
    }

    @discardableResult
    func update(_ item: ItemRecord, with draft: ItemDraft) -> Bool {
        guard draft.isValid else { return false }
        return perform {
            try self.service.updateItem(id: item.id, with: draft)
            self.items = try self.service.fetchItems(ownerUID: self.ownerUID)
        }
    }

    func delete(_ item: ItemRecord) {
        perform {
            try self.service.deleteItem(id: item.id)
            self.items = try self.service.fetchItems(ownerUID: self.ownerUID)
        }
    }

    // MARK: Error handling

    /// Runs a throwing action and turns any error into `errorMessage`.
    @discardableResult
    private func perform(_ action: () throws -> Void) -> Bool {
        do {
            try action()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
