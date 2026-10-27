//
//  CenterAlertNotifier.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import UserNotifications

/// Sends the "you are near a centre" alert. A fake stands in for it in tests.
@MainActor
protocol CentreAlertNotifying {
    func sendAlert(centreID: String, centreName: String, categories: [ItemCategory]) async
}

/// Local notification. (The lecturer confirmed local notifications count as push notifications.)
@MainActor
struct CentreAlertNotifier: CentreAlertNotifying {
    init() {
        // Without a delegate iOS hides notifications while the app is open. Only set it if nobody has.
        let center = UNUserNotificationCenter.current()
        if center.delegate == nil { center.delegate = ForegroundBannerDelegate.shared }
    }

    func sendAlert(centreID: String, centreName: String, categories: [ItemCategory]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        let current = await center.notificationSettings()
        guard current.authorizationStatus == .authorized || current.authorizationStatus == .provisional else { return }

        let names = ListFormatter.localizedString(byJoining: categories.map { $0.displayName.lowercased() })
        let content = UNMutableNotificationContent()
        content.title = "You\u{2019}re near \(centreName)"
        content.body = "It accepts your \(names). Good time to drop them off."
        content.sound = .default
        content.userInfo = ["centreID": centreID]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "centre-alert-\(centreID)", content: content, trigger: trigger)
        try? await center.add(request)
    }
}

/// Shows alerts as banners even while the app is open.
final class ForegroundBannerDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundBannerDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
