//
//  RecyclingStatsTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Testing
@testable import ecyclelk   // your module name

struct RecyclingStatsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func item(_ status: ItemStatus, kg: Double = 1, added: Date, recycled: Date? = nil) -> ItemRecord {
        ItemRecord(id: UUID(), name: "Item", category: .laptops, condition: .working, notes: "",
                   weightKg: kg, dateAdded: added, status: status, recycledDate: recycled)
    }

    @Test func noItemsGivesZeroEverything() {
        let stats = RecyclingStats.make(from: [], now: date(2026, 10, 24), calendar: calendar)
        #expect(stats == RecyclingStats.empty)
        #expect(stats.completionRatePercent == 0)
    }

    @Test func countsAndCompletionRate() {
        let now = date(2026, 10, 24)
        let items = [
            item(.saved, added: now),
            item(.planned, added: now),
            item(.recycled, added: now, recycled: now),
            item(.recycled, added: now, recycled: now)
        ]
        let stats = RecyclingStats.make(from: items, now: now, calendar: calendar)
        #expect(stats.itemsRecorded == 4)
        #expect(stats.itemsRecycled == 2)
        #expect(stats.activeItems == 2)
        #expect(stats.completionRatePercent == 50)
    }

    @Test func completionRateIsRounded() {
        let now = date(2026, 10, 24)
        let oneOfThree = [item(.recycled, added: now, recycled: now), item(.saved, added: now), item(.saved, added: now)]
        #expect(RecyclingStats.make(from: oneOfThree, now: now, calendar: calendar).completionRatePercent == 33)
    }

    @Test func kilogramsOnlyCountRecycledItems() {
        let now = date(2026, 10, 24)
        let items = [
            item(.saved, kg: 5, added: now),
            item(.recycled, kg: 2, added: now, recycled: now),
            item(.recycled, kg: 1.5, added: now, recycled: now)
        ]
        #expect(RecyclingStats.make(from: items, now: now, calendar: calendar).kgRecycled == 3.5)
    }

    @Test func thisMonthAndThisYearAreSeparated() {
        let now = date(2026, 10, 24)
        let items = [
            item(.recycled, added: date(2026, 10, 1), recycled: date(2026, 10, 10)),   // this month
            item(.recycled, added: date(2026, 3, 1), recycled: date(2026, 3, 18)),     // this year, not this month
            item(.recycled, added: date(2025, 3, 1), recycled: date(2025, 3, 18))      // last year
        ]
        let stats = RecyclingStats.make(from: items, now: now, calendar: calendar)
        #expect(stats.recycledThisMonth == 1)
        #expect(stats.recycledThisYear.count == 2)
        #expect(stats.addedThisMonth == 1)
    }
}
