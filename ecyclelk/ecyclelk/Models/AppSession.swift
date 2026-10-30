//
//  AppSession.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

// Who is signed in, plus the app lock and sign-out action.

@MainActor
@Observable
final class AppSession {
    let user: AuthUser
    let lock: AppLockViewModel
    private let onSignOut: () -> Void
    var showsHistory = false

    init(user: AuthUser, lock: AppLockViewModel, onSignOut: @escaping () -> Void) {
        self.user = user
        self.lock = lock
        self.onSignOut = onSignOut
    }

    func signOut() { onSignOut() }
}
