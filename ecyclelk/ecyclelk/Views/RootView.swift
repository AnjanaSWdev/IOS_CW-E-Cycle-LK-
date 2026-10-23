//
//  RootView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct RootView : View{
    
    @State private var auth: AuthViewModel
    
    init(auth: AuthViewModel){
        
        _auth = State(initialValue: auth)
    }
    
    var body: some View {
        
        switch auth.state {
        case .signedOut:
            AuthView(viewModel: auth)
        case .signedIn(let user):
            MainTabView(user: user, onSignOut: {auth.signOut()})
        }
    }
}
