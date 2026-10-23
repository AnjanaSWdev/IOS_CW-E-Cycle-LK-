//
//  MainTabView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI
internal import CoreData

struct MainTabView: View{
    
    let user: AuthUser
    let onSignOut: () -> Void
    @State private var itemsViewModel: ItemsViewModel
        
    init(user: AuthUser, onSignOut: @escaping () -> Void){
        self.user = user
        self.onSignOut = onSignOut
        let context = PersistenceController.shared.container.viewContext; _itemsViewModel = State(initialValue: ItemsViewModel(service: CoreDataItemsService(context: context), ownerUID: user.uid))
    }
    
    var body: some View{
        
        TabView{
            Tab("Home", systemImage: "house"){
                HomePlaceholderView(user: user, onSignOut: onSignOut)
            }
            Tab("My items", systemImage: "shippingbox"){
                ItemsView(viewModel: itemsViewModel)
            }
            Tab("Centres", systemImage: "mapping.and.eclipse"){
                ComingSoonView(title: "Centers")
            }
            Tab("Plans", systemImage: "calendar"){
                ComingSoonView(title: "Plans")
            }
            Tab("History", systemImage: "clock.arrow.circlepath"){
                ComingSoonView(title: "History")
            }
        }
        .tint(.ecGreen)
    }
}

struct HomePlaceholderView: View{
    
    let user: AuthUser
    let onSignOut: () -> Void
    
    var body: some View{
        VStack(spacing: 16){
            Text("Welcome back, \(user.name.isEmpty ? user.email : user.name)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Button("Sign out", action: onSignOut)
                .buttonStyle(.borderedProminent)
                .tint(.ecGreen)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ecBackground)
    }
}

struct ComingSoonView: View{
    
    let title: String
    
    var body: some View{
        ContentUnavailableView(title, systemImage: "hammer", description: Text("This screen is coming soon."))
            .background(Color.ecBackground)
    }
}
