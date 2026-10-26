//
//  MainTabView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI
internal import CoreData

enum AppTab: Hashable {
    case home, items, centres, plans, history
}

struct MainTabView: View {
    @State private var session: AppSession
    @State private var selectedTab: AppTab = .home
    @State private var itemsViewModel: ItemsViewModel
    @State private var plansViewModel: PlansViewModel
    @State private var impactViewModel: ImpactViewModel

    init(user: AuthUser, lock: AppLockViewModel, onSignOut: @escaping () -> Void) {
        _session = State(initialValue: AppSession(user: user, lock: lock, onSignOut: onSignOut))

        let context = PersistenceController.shared.container.viewContext
        let itemsService = CoreDataItemsService(context: context)
        let plansService = CoreDataPlansService(context: context)

        _itemsViewModel = State(initialValue: ItemsViewModel(service: itemsService, ownerUID: user.uid))
        _plansViewModel = State(initialValue: PlansViewModel(
            plansService: plansService,
            itemsService: itemsService,
            reminders: UserNotificationScheduler(),
            ownerUID: user.uid
        ))
        _impactViewModel = State(initialValue: ImpactViewModel(
            items: itemsService,
            plans: plansService,
            ownerUID: user.uid
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView(viewModel: impactViewModel,
                         onAddItem: { selectedTab = .items },
                         onFindCentre: { selectedTab = .centres })
            }
            Tab("My items", systemImage: "shippingbox", value: AppTab.items) {
                ItemsView(viewModel: itemsViewModel)
            }
            Tab("Centres", systemImage: "mappin.and.ellipse", value: AppTab.centres) {
                ComingSoonView(title: "Centres")
            }
            Tab("Plans", systemImage: "calendar", value: AppTab.plans) {
                PlansView(viewModel: plansViewModel)
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView(viewModel: impactViewModel)
            }
        }
        .tint(.ecGreen)
        .environment(session)
    }
}

struct ComingSoonView: View {
    let title: String

    var body: some View {
        ContentUnavailableView(title, systemImage: "hammer",
                               description: Text("This screen is coming soon."))
            .background(Color.ecBackground)
    }
}
