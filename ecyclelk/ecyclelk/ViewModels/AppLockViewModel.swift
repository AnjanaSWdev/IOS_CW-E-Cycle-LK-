//
//  AppLockViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppLockViewModel {
    static let settingKey = "faceIDEnabled"

    private(set) var isLocked: Bool
    private(set) var isEnabled: Bool
    private(set) var lastAttemptFailed = false
    /// Shown in an alert in Settings when turning the lock on does not work.
    var message: String?

    private let biometrics: BiometricAuthenticating
    private let defaults: UserDefaults

    init(biometrics: BiometricAuthenticating, defaults: UserDefaults = .standard) {
        self.biometrics = biometrics
        self.defaults = defaults
        let enabled = defaults.bool(forKey: Self.settingKey)
        isEnabled = enabled
        // Locked at launch when the setting is on.
        isLocked = enabled && biometrics.isAvailable
    }

    /// Turning the lock ON asks for Face ID once, so you can't lock yourself out.
    func setEnabled(_ newValue: Bool) async {
        message = nil
        if newValue {
            guard biometrics.isAvailable else {
                message = "Face ID or a device passcode isn't set up on this device."
                return
            }
            guard await biometrics.authenticate(reason: "Confirm to turn on app lock") else {
                message = "Couldn't verify it's you, so app lock stays off."
                return
            }
        }
        isEnabled = newValue
        defaults.set(newValue, forKey: Self.settingKey)
    }

    /// Called when the app moves to the background.
    func lockIfNeeded() {
        if isEnabled && biometrics.isAvailable {
            isLocked = true
        }
    }

    func unlock() async {
        guard isLocked else { return }
        if await biometrics.authenticate(reason: "Unlock E-Cycle LK") {
            isLocked = false
            lastAttemptFailed = false
        } else {
            lastAttemptFailed = true
        }
    }
}
