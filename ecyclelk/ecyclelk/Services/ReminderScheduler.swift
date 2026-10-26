//
//  ReminderScheduler.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import UserNotifications

/// Schedules local notifications. The view model uses this protocol, so tests use a fake.
@MainActor
protocol ReminderSchedulerProtocol {
    func requestAuthorization() async -> Bool
    func scheduleReminder(id: String, title: String, body: String, at fireDate: Date) async throws
    func cancelReminder(id: String)
}

@MainActor
final class UserNotificationScheduler: ReminderSchedulerProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(id: String, title: String, body: String, at fireDate: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
