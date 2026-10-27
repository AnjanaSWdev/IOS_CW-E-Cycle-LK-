//
//  NewListingView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI

/// Offer one of your saved items to the community.
struct NewListingView: View {
    @Bindable var viewModel: CommunityViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ListingDraft()
    @State private var isPublishing = false

    var body: some View {
        NavigationStack {
            Form {
                if let message = viewModel.errorMessage {
                    Section { CommunityMessageBanner(text: message) { viewModel.errorMessage = nil } }
                }

                itemSection

                if draft.sourceItemID != nil {
                    detailsSection
                    priceSection
                    handoverSection
                    safetySection

                    if let problem = draft.firstProblem {
                        Section {
                            Label(problem.message, systemImage: "info.circle")
                                .font(.footnote)
                                .foregroundStyle(Color.ecWarningInk)
                        }
                    }
                }
            }
            .navigationTitle("List an item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") { publish() }
                        .disabled(draft.firstProblem != nil || isPublishing)
                }
            }
        }
        .onAppear {
            viewModel.errorMessage = nil
            viewModel.loadAvailableItems()
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var itemSection: some View {
        Section {
            if viewModel.availableItems.isEmpty {
                Text("You have no saved items to offer. Add one in My items first. Items already planned for recycling or listed are not shown.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)
            } else {
                Picker("Item", selection: $draft.sourceItemID) {
                    Text("Choose an item").tag(UUID?.none)
                    ForEach(viewModel.availableItems) { item in
                        Text(item.name).tag(Optional(item.id))
                    }
                }
                .onChange(of: draft.sourceItemID) { _, newValue in
                    if let item = viewModel.availableItems.first(where: { $0.id == newValue }) {
                        draft.apply(item)
                    }
                }
            }
        } header: {
            Text("Which item?")
        } footer: {
            Text("Working or repairable gadgets are better reused than recycled. If nobody asks within a week we will suggest recycling it.")
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        Section("About the item") {
            TextField("Title", text: $draft.title)

            Picker("Condition", selection: $draft.condition) {
                ForEach(ListingCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .pickerStyle(.segmented)
            Text(draft.condition.detail)
                .font(.footnote)
                .foregroundStyle(Color.ecMuted)

            TextField("What works, what doesn\u{2019}t, what\u{2019}s included?", text: $draft.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    @ViewBuilder
    private var priceSection: some View {
        Section {
            Picker("Offer", selection: $draft.mode) {
                ForEach(ListingMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if draft.mode == .sale {
                HStack {
                    Text("Rs.")
                    TextField("Price", text: $draft.priceText)
                        .keyboardType(.numberPad)
                }
            }
        } footer: {
            Text("Price is agreed between you and the buyer. E-Cycle LK does not handle payments, so only take payment in person.")
        }
    }

    @ViewBuilder
    private var handoverSection: some View {
        Section {
            Picker("District", selection: $draft.district) {
                Text("Choose a district").tag("")
                ForEach(SriLankaDistricts.all, id: \.self) { district in
                    Text(district).tag(district)
                }
            }
            TextField("Handover idea (optional)", text: $draft.handoverNote, axis: .vertical)
        } header: {
            Text("Where can it be collected?")
        } footer: {
            Text("Only the district is shown. Share your exact address only with the person you choose, and meet somewhere public if you can, such as a recycling centre or shop.")
        }
    }

    @ViewBuilder
    private var safetySection: some View {
        Section {
            if draft.requiresDataConfirmation {
                Toggle("I have signed out of my accounts and erased my personal data", isOn: $draft.confirmsDataRemoved)
            }
            Toggle("The battery is not swollen, leaking or overheating", isOn: $draft.confirmsBatterySafe)
            Toggle("This item is mine to pass on", isOn: $draft.confirmsOwnership)
        } header: {
            Text("Safety checks")
        }
        .tint(Color.ecGreen)
    }

    // MARK: Actions

    private func publish() {
        isPublishing = true
        Task {
            let success = await viewModel.createListing(draft)
            isPublishing = false
            if success { dismiss() }
        }
    }
}
