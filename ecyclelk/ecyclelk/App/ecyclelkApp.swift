//
//  ecyclelkApp.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-18.
//



import SwiftUI
internal import CoreData
import FirebaseCore

@main
struct ecyclelkApp: App {
    let persistenceController = PersistenceController.shared
    @State private var auth: AuthViewModel

    init() {
        // Firebase must be configured BEFORE anything touches Firebase Auth,
        // so the view model is created here after configure().
        FirebaseApp.configure()
        _auth = State(initialValue: AuthViewModel(service: FirebaseAuthService()))
    }

    var body: some Scene {
        WindowGroup {
            RootView(auth: auth)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
