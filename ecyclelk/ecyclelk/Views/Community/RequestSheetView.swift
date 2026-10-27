//
//  RequestSheetView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI

/// The form a person fills in to ask for an item.
struct RequestSheetView: View {
    @Bindable var viewModel: CommunityViewModel
    let listing: Listing
    let onSent: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = RequestDraft()
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Form {
                if let message = viewModel.errorMessage {
                    Section { CommunityMessageBanner(text: message) { viewModel.errorMessage = nil } }
                }

                Section {
                    Picker("Why do you want it?", selection: $draft.purpose) {
                        ForEach(RequestPurpose.allCases) { purpose in
                            Text(purpose.displayName).tag(purpose)
                        }
                    }
                } footer: {
                    Text("The owner chooses who gets the item. Being honest about what you will do with it helps.")
                }

                Section {
                    TextField("Say hello and explain your plan", text: $draft.message, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Message to the owner")
                } footer: {
                    Text("\(draft.trimmedMessage.count) / \(RequestDraft.maxMessageLength)")
                }

                Section {
                    TextField("Phone number", text: $draft.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("Your phone number")
                } footer: {
                    Text("Only \(listing.ownerName.isEmpty ? "the owner" : listing.ownerName) can see this. It is never shown to anyone else.")
                }

                if let problem = draft.firstProblem {
                    Section {
                        Label(problem.message, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(Color.ecWarningInk)
                    }
                }
            }
            .navigationTitle("Request item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { send() }
                        .disabled(draft.firstProblem != nil || isSending)
                }
            }
        }
        .onAppear { viewModel.errorMessage = nil }
    }

    private func send() {
        isSending = true
        Task {
            let success = await viewModel.submitRequest(draft, for: listing)
            isSending = false
            if success {
                dismiss()
                onSent()
            }
        }
    }
}
