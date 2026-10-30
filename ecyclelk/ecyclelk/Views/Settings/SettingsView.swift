//
//  SettingsView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct SettingsView: View {
    let user: AuthUser
    let lock: AppLockViewModel
    let onSignOut: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                        HStack(spacing: 14) {
                            AvatarView(initials: user.initials, size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name.isEmpty ? "No name set" : user.name).font(.headline)
                                Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    
                }

                Section {
                    Toggle("Lock app with Face ID", isOn: Binding(
                        get: { lock.isEnabled },
                        set: { newValue in Task { await lock.setEnabled(newValue) } }
                    ))
                } header: {
                    Text("Security")
                } footer: {
                    Text("Uses Face ID, or your device passcode if Face ID isn't available. The app locks each time you leave it.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Button("Sign out", role: .destructive) { confirmSignOut = true }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Sign out of E-Cycle LK?",
                                isPresented: $confirmSignOut,
                                titleVisibility: .visible) {
                Button("Sign out", role: .destructive) { onSignOut() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("App lock", isPresented: Binding(
                get: { lock.message != nil },
                set: { if !$0 { lock.message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(lock.message ?? "")
            }
        }
    }
}
