//
//  ContentView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-18.
//

import SwiftUI
internal import CoreData

struct ContentView: View {
    var body: some View {
        ItemsView(
            viewModel: ItemsViewModel(
                service: CoreDataItemsService(
                    context: PersistenceController.shared.container.viewContext
                )
            )
        )
    }
}

