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
    @State private var showsCommunity = false
    @State private var itemsViewModel: ItemsViewModel
    @State private var plansViewModel: PlansViewModel
    @State private var impactViewModel: ImpactViewModel
    @State private var centresViewModel: CentresViewModel
    @State private var communityViewModel: CommunityViewModel
    @State private var showsScan = false
    @State private var scanViewModel: ScanViewModel
    @State private var geofenceViewModel: GeofenceViewModel

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
        let locationService = LocationService()

        _centresViewModel = State(initialValue: CentresViewModel(
            catalog: BundledCentresCatalog(),
            location: locationService
        ))

        _geofenceViewModel = State(initialValue: GeofenceViewModel(
            service: CoreLocationGeofenceService(),
            notifier: CentreAlertNotifier(),
            store: UserDefaultsGeofenceStore(),
            items: itemsService,
            catalog: BundledCentresCatalog(),
            location: locationService,
            ownerUID: user.uid,
            now: { Date() },
            cooldown: GeofenceViewModel.defaultCooldown
        ))
        _communityViewModel = State(initialValue: CommunityViewModel(
            service: FirestoreCommunityService(),
            items: itemsService,
            user: user
        ))
        _scanViewModel = State(initialValue: ScanViewModel(
            classifier: VisionItemClassifier(),
            items: itemsService,
            ownerUID: user.uid
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView(viewModel: impactViewModel,
                         onAddItem: { selectedTab = .items },
                         onFindCentre: { selectedTab = .centres },
                         onOpenCommunity: { showsCommunity = true },
                         onOpenScan: { scanViewModel.reset(); showsScan = true })
                
            }
            Tab("My items", systemImage: "shippingbox", value: AppTab.items) {
                ItemsView(viewModel: itemsViewModel)
            }
            Tab("Centres", systemImage: "mappin.and.ellipse", value: AppTab.centres) {
                CentresView(viewModel: centresViewModel, geofence: geofenceViewModel)
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
        .task { geofenceViewModel.refresh() }
        .onChange(of: selectedTab) { _, _ in geofenceViewModel.refresh() }
        .fullScreenCover(isPresented: $showsCommunity) {
            CommunityView(
                viewModel: communityViewModel,
                onClose: { showsCommunity = false },
                onPlanRecycling: {
                    showsCommunity = false
                    selectedTab = .plans
                }
            )
            .tint(.ecGreen)
        }
        .fullScreenCover(isPresented: $showsScan) {
            ScanView(
                viewModel: scanViewModel,
                onClose: { showsScan = false },
                onSaved: {
                    showsScan = false
                    itemsViewModel.load()
                    impactViewModel.load()
                    geofenceViewModel.refresh()
                    selectedTab = .items
                }
            )
            .tint(.ecGreen)
        }
        .onChange(of: showsCommunity) { _, isShowing in
            // Listing or handing over an item changes its status, so refresh the other tabs.
            if !isShowing {
                itemsViewModel.load()
                plansViewModel.load()
                impactViewModel.load()
                geofenceViewModel.refresh()
            }
        }
    }
}

/// Placeholder for screens that are not built yet.
struct ComingSoonView: View {
    let title: String

    var body: some View {
        ContentUnavailableView(title, systemImage: "hammer",
                               description: Text("This screen is coming soon."))
            .background(Color.ecBackground)
    }
}
