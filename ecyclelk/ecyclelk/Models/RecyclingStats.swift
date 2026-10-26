//
//  RecyclingStats.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation

struct RecyclingStats: Equatable{
    var itemsRecorded = 0
    var itemsRecycled = 0
    var activeItems = 0
    var kgRecycled = 0.0
    var addedThisMonth = 0
    var recycledThisMonth = 0
    var completionRatePercent = 0
    
    var recycledThisYear: [ItemRecord] = []
    var kgRecycledThisYear = 0.0
    
    static let empty = RecyclingStats()
    
    static func make(from items: [ItemRecord], now: Date, calendar: Calendar = .current) -> RecyclingStats{
        
        let recycled = items.filter { $0.status == .recycled}
        let thisYear = recycled
            .filter{ item in
                guard let date = item.recycledDate else{ return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
            .sorted { ($0.recycledDate ?? .distantPast) > ($1.recycledDate ?? .distantPast)}
        
        var stats = RecyclingStats()
        stats.itemsRecorded = items.count
        stats.itemsRecycled = recycled.count
        stats.activeItems = items.count - recycled.count
        stats.kgRecycled = recycled.reduce(0) { $0 + $1.weightKg }
        stats.addedThisMonth = items.filter { calendar.isDate($0.dateAdded, equalTo: now, toGranularity: .month)}.count
        stats.recycledThisMonth = recycled.filter{
            item in guard let date = item.recycledDate else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
        stats.completionRatePercent = items.isEmpty
        ? 0
        : Int((Double(recycled.count) / Double(items.count) * 100).rounded())
        stats.recycledThisYear = thisYear
        stats.kgRecycledThisYear = thisYear.reduce(0) { $0 + $1.weightKg}
        return stats
    }
    
}
    

