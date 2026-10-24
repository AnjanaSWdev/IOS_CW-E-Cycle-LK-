//
//  MainTabView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI
internal import CoreData

struct MainTabView: View {
    @State private var session: AppSession
    @State private var itemsViewModel: ItemsViewModel
    @State private var plansViewModel: PlansViewModel

    init(user: AuthUser, lock: AppLockViewModel, onSignOut: @escaping () -> Void) {
        _session = State(initialValue: AppSession(user: user, lock: lock, onSignOut: onSignOut))
        let context = PersistenceController.shared.container.viewContext
        _itemsViewModel = State(initialValue: ItemsViewModel(
            service: CoreDataItemsService(context: context),
            ownerUID: user.uid
        ))
        _plansViewModel = State(initialValue: PlansViewModel(
            plansService: CoreDataPlansService(context: context),
            itemsService: CoreDataItemsService(context: context),
            reminders: UserNotificationScheduler(),
            ownerUID: user.uid
        ))
    }

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomePlaceholderView()
            }
            Tab("My items", systemImage: "shippingbox") {
                ItemsView(viewModel: itemsViewModel)
            }
            Tab("Centres", systemImage: "mappin.and.ellipse") {
                ComingSoonView(title: "Centres")
            }
            Tab("Plans", systemImage: "calendar") {
                PlansView(viewModel: plansViewModel)
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                ComingSoonView(title: "History")
            }
        }
        .tint(.ecGreen)
        .environment(session)
    }
}

/// Temporary Home screen until the dashboard is built.
struct HomePlaceholderView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        NavigationStack {
            Text("Welcome back, \(session.user.name.isEmpty ? session.user.email : session.user.name)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.ecBackground)
                .navigationBarTitleDisplayMode(.inline)
                .ecToolbar()
        }
    }
}

struct ComingSoonView: View{
    
    let title: String
    
    var body: some View{
        ContentUnavailableView(title, systemImage: "hammer", description: Text("This screen is coming soon."))
            .background(Color.ecBackground)
    }
}
