//
//  AppLockViewModelTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Testing
@testable import ecyclelk   // your module name

@MainActor
private final class FakeBiometrics: BiometricAuthenticating {
    var isAvailable = true
    var succeeds = true
    func authenticate(reason: String) async -> Bool { succeeds }
}

@MainActor
struct AppLockViewModelTests {
    /// A fresh, empty settings store for each test.
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    }

    @Test func notLockedAtLaunchWhenSettingIsOff() {
        let lock = AppLockViewModel(biometrics: FakeBiometrics(), defaults: makeDefaults())
        #expect(!lock.isLocked)
    }

    @Test func lockedAtLaunchWhenSettingIsOn() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppLockViewModel.settingKey)
        let lock = AppLockViewModel(biometrics: FakeBiometrics(), defaults: defaults)
        #expect(lock.isLocked)
    }

    @Test func enablingNeedsSuccessfulAuthentication() async {
        let biometrics = FakeBiometrics()
        biometrics.succeeds = false
        let lock = AppLockViewModel(biometrics: biometrics, defaults: makeDefaults())
        await lock.setEnabled(true)
        #expect(!lock.isEnabled)
        #expect(lock.message != nil)
    }

    @Test func enablingFailsWhenBiometricsUnavailable() async {
        let biometrics = FakeBiometrics()
        biometrics.isAvailable = false
        let lock = AppLockViewModel(biometrics: biometrics, defaults: makeDefaults())
        await lock.setEnabled(true)
        #expect(!lock.isEnabled)
    }

    @Test func lockIfNeededLocksOnlyWhenEnabled() async {
        let lock = AppLockViewModel(biometrics: FakeBiometrics(), defaults: makeDefaults())
        lock.lockIfNeeded()
        #expect(!lock.isLocked)
        await lock.setEnabled(true)
        lock.lockIfNeeded()
        #expect(lock.isLocked)
    }

    @Test func successfulUnlockOpensTheApp() async {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppLockViewModel.settingKey)
        let lock = AppLockViewModel(biometrics: FakeBiometrics(), defaults: defaults)
        await lock.unlock()
        #expect(!lock.isLocked)
    }

    @Test func failedUnlockStaysLocked() async {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppLockViewModel.settingKey)
        let biometrics = FakeBiometrics()
        biometrics.succeeds = false
        let lock = AppLockViewModel(biometrics: biometrics, defaults: defaults)
        await lock.unlock()
        #expect(lock.isLocked)
        #expect(lock.lastAttemptFailed)
    }
}
