//
//  ecyclelkApp.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-18.
//



import SwiftUI
internal import CoreData
import FirebaseCore
import UserNotifications

@main
struct ecyclelkApp: App {
    let persistenceController = PersistenceController.shared
    @State private var auth: AuthViewModel
    @State private var lock: AppLockViewModel
    
    init() {
        
        // Firebase must be configured BEFORE anything touches Firebase Auth,
        // so the view model is created here after configure().
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
        _auth = State(initialValue: AuthViewModel(service: FirebaseAuthService()))
        _lock = State(initialValue: AppLockViewModel(biometrics: LocalAuthBiometrics()))
    }

    var body: some Scene {
        WindowGroup {
            RootView(auth: auth, lock: lock)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
