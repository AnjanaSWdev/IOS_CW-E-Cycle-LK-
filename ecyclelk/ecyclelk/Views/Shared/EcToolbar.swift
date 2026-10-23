//
//  EcToolbar.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

/// The prototype's top bar: logo on the left, avatar on the right.
/// Tapping the avatar opens Settings. Add the bell here when the inbox exists.
struct EcToolbar: ViewModifier {
    @Environment(AppSession.self) private var session
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.3.trianglepath")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.ecGreen, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("E-Cycle").font(.subheadline.bold()).foregroundStyle(Color.ecInk)
                            Text("SRI LANKA").font(.caption2.bold()).foregroundStyle(Color.ecGreen)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("E-Cycle LK, Sri Lanka")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        AvatarView(initials: session.user.initials)
                    }
                    .accessibilityLabel("Profile and settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(user: session.user, lock: session.lock, onSignOut: session.signOut)
            }
    }
}

extension View {
    func ecToolbar() -> some View { modifier(EcToolbar()) }
}
