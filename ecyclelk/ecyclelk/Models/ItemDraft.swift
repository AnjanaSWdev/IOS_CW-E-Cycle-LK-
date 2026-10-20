//
//  ItemDraft.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import Foundation

struct ItemDraft: Equatable {
    var name: String
    var category: ItemCategory
    var condition: ItemCondition
    var notes: String
    var weightKg: Double

    /// A blank draft for the "Add item" form.
    init(
        name: String = "",
        category: ItemCategory = .mobilePhones,
        condition: ItemCondition = .working,
        notes: String = "",
        weightKg: Double? = nil
    ) {
        self.name = name
        self.category = category
        self.condition = condition
        self.notes = notes
        self.weightKg = weightKg ?? category.defaultWeightKg
    }

    /// A draft pre-filled from an existing item, for the "Edit item" form.
    init(record: ItemRecord) {
        self.name = record.name
        self.category = record.category
        self.condition = record.condition
        self.notes = record.notes
        self.weightKg = record.weightKg
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedNotes: String { notes.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The only required field is a name.
    var isValid: Bool { !trimmedName.isEmpty }
}
