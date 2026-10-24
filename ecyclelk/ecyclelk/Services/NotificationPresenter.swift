//
//  NotificationPresenter.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import UserNotifications

final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
