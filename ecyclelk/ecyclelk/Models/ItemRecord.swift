//
//  ItemRecord.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import Foundation

struct ItemRecord: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: ItemCategory
    var condition: ItemCondition
    var notes: String
    var weightKg: Double
    var dateAdded: Date
    var status: ItemStatus
    var recycledDate: Date? = nil
    var centreName: String? = nil
}
