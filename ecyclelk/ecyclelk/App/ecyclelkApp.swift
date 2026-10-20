//
//  ecyclelkApp.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-18.
//

import SwiftUI
internal import CoreData

@main
struct ecyclelkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
