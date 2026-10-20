//
//  CoreDataItemsService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

internal import CoreData
import Foundation

/// Core Data implementation of `ItemsServiceProtocol`.
///
/// Assumes the `EwasteItem` entity uses Xcode's default "Class Definition"
/// code generation. Optionality quirks of the generated properties are
/// handled with `as Type?` casts in `makeRecord`.
@MainActor
final class CoreDataItemsService: ItemsServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Read

    func fetchItems(ownerUID: String) throws -> [ItemRecord] {
        let request = NSFetchRequest<EwasteItem>(entityName: "EwasteItem")
        request.predicate = NSPredicate(
            format: "ownerUID == %@ AND status != %@",
            ownerUID, ItemStatus.recycled.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EwasteItem.dateAdded, ascending: false)]
        return try context.fetch(request).compactMap(makeRecord)
    }

    // MARK: - Create

    @discardableResult
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord {
        let object = EwasteItem(context: context)
        object.id = UUID()
        object.dateAdded = Date()
        object.status = ItemStatus.saved.rawValue
        object.ownerUID = ownerUID
        apply(draft, to: object)
        try saveContext()

        guard let record = makeRecord(object) else { throw ItemsServiceError.notFound }
        return record
    }

    // MARK: - Update

    func updateItem(id: UUID, with draft: ItemDraft) throws {
        let object = try fetchObject(id: id)
        apply(draft, to: object)
        try saveContext()
    }

    // MARK: - Delete

    func deleteItem(id: UUID) throws {
        let object = try fetchObject(id: id)
        context.delete(object)
        try saveContext()
    }

    // MARK: - Helpers

    private func fetchObject(id: UUID) throws -> EwasteItem {
        let request = NSFetchRequest<EwasteItem>(entityName: "EwasteItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let object = try context.fetch(request).first else {
            throw ItemsServiceError.notFound
        }
        return object
    }

    private func apply(_ draft: ItemDraft, to object: EwasteItem) {
        object.name = draft.trimmedName
        object.category = draft.category.rawValue
        object.condition = draft.condition.rawValue
        object.notes = draft.trimmedNotes.isEmpty ? nil : draft.trimmedNotes
        object.weightKg = draft.weightKg
    }

    /// Save, and undo the pending changes if the save fails so the context
    /// never keeps half-written data.
    private func saveContext() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func makeRecord(_ object: EwasteItem) -> ItemRecord? {
        // `as Type?` makes this compile whether Xcode generated the
        // property as optional or not.
        guard let id = object.id as UUID? else { return nil }
        return ItemRecord(
            id: id,
            name: (object.name as String?) ?? "",
            category: ItemCategory(rawValue: (object.category as String?) ?? "") ?? .accessories,
            condition: ItemCondition(rawValue: (object.condition as String?) ?? "") ?? .working,
            notes: (object.notes as String?) ?? "",
            weightKg: object.weightKg,
            dateAdded: (object.dateAdded as Date?) ?? Date(),
            status: ItemStatus(rawValue: (object.status as String?) ?? "") ?? .saved
        )
    }
}


