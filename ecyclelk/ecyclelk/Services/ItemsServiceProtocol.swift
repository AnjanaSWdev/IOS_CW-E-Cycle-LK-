//
//  ItemsServiceProtocol.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import Foundation

@MainActor
protocol ItemsServiceProtocol {
    /// Items that are not yet recycled, newest first.
    func fetchItems(ownerUID: String) throws -> [ItemRecord]
    @discardableResult
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord
    func updateItem(id: UUID, with draft: ItemDraft) throws
    func deleteItem(id: UUID) throws
}

enum ItemsServiceError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: return "That item could not be found. It may already have been deleted."
        }
    }
}
