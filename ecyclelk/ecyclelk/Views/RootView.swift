//
//  RootView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI


/// Decides what to show: onboarding, sign-in, or the main tabs (with the lock screen on top).
struct RootView: View {
    @State private var auth: AuthViewModel
    @State private var lock: AppLockViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init(auth: AuthViewModel, lock: AppLockViewModel) {
        _auth = State(initialValue: auth)
        _lock = State(initialValue: lock)
    }

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else {
                switch auth.state {
                case .signedOut:
                    AuthView(viewModel: auth)
                case .signedIn(let user):
                    ZStack {
                        MainTabView(user: user, lock: lock, onSignOut: { auth.signOut() })
                            .accessibilityHidden(lock.isLocked)
                        if lock.isLocked {
                            LockView(lock: lock)
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Lock when the app goes to the background (not on .inactive, which also
            // happens while the Face ID prompt itself is showing).
            if phase == .background, case .signedIn = auth.state {
                lock.lockIfNeeded()
            }
        }
    }
}
