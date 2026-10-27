//
//  ListingDetailView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI

/// One listing. What you see depends on who you are: the owner, someone who already asked, or a visitor.
struct ListingDetailView: View {
    @Bindable var viewModel: CommunityViewModel
    let listingID: String
    let onPlanRecycling: () -> Void

    @State private var showsRequestSheet = false
    @State private var acceptTarget: ListingRequest?
    @State private var confirmWithdraw = false
    @State private var isWorking = false

    private var listing: Listing? { viewModel.listing(withID: listingID) }
    private var isOwner: Bool { listing?.ownerUID == viewModel.user.uid }

    var body: some View {
        ScrollView {
            if let listing {
                VStack(alignment: .leading, spacing: 16) {
                    if let message = viewModel.errorMessage {
                        CommunityMessageBanner(text: message) { viewModel.errorMessage = nil }
                    }
                    if let notice = viewModel.noticeMessage {
                        CommunityMessageBanner(text: notice, isError: false) { viewModel.noticeMessage = nil }
                    }

                    header(listing)
                    detailsCard(listing)

                    if isOwner {
                        ownerSection(listing)
                    } else {
                        visitorSection(listing)
                        safetyCard
                    }
                }
                .padding(16)
            } else {
                ContentUnavailableView("Listing not found", systemImage: "questionmark.folder",
                                       description: Text("It may have been removed. Go back and pull down to refresh."))
            }
        }
        .background(Color.ecBackground)
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let listing, !isOwner {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(["Not an e-waste item", "Unsafe or hazardous", "Scam or misleading", "Something else"], id: \.self) { reason in
                            Button(reason) { Task { await viewModel.report(listing, reason: reason) } }
                        }
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                }
            }
        }
        .task(id: listingID) {
            viewModel.errorMessage = nil
            viewModel.noticeMessage = nil
            if let listing, listing.ownerUID == viewModel.user.uid {
                await viewModel.loadRequests(for: listing)
            }
        }
        .sheet(isPresented: $showsRequestSheet) {
            if let listing {
                RequestSheetView(viewModel: viewModel, listing: listing) {}
            }
        }
        .sheet(item: $acceptTarget) { request in
            if let listing {
                AcceptContactSheet(viewModel: viewModel, listing: listing, request: request) {
                    acceptTarget = nil
                }
            }
        }
        .confirmationDialog("Withdraw this listing?", isPresented: $confirmWithdraw, titleVisibility: .visible) {
            Button("Withdraw listing", role: .destructive) {
                guard let listing else { return }
                run { _ = await viewModel.withdraw(listing) }
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Pending requests will be declined and the item goes back to My items.")
        }
    }

    // MARK: Shared parts

    private func header(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(listing.title)
                .font(.title.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)], alignment: .leading, spacing: 6) {
                CommunityBadge(text: listing.priceText)
                CommunityBadge(text: listing.condition.displayName, background: Color.white)
                CommunityBadge(text: listing.category.displayName, background: listing.category.tint)
                if listing.status != .open {
                    CommunityBadge(text: listing.status.displayName, background: Color.ecWarning, foreground: Color.ecWarningInk)
                }
            }
        }
    }

    private func detailsCard(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(listing.description)
                .font(.body)
                .foregroundStyle(Color.ecInk)
            Divider()
            row(symbol: "mappin.and.ellipse", text: listing.district)
            if !listing.handoverNote.isEmpty {
                row(symbol: "arrow.left.arrow.right", text: listing.handoverNote)
            }
            row(symbol: "person", text: "Listed by \(listing.ownerName.isEmpty ? "a community member" : listing.ownerName)")
            if listing.status == .open {
                let days = listing.daysLeft(now: viewModel.currentDate)
                row(symbol: "clock", text: days <= 1 ? "Last day to request" : "\(days) days left")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    private func row(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Color.ecGreen)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.ecInk)
        }
        .accessibilityElement(children: .combine)
    }

    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Stay safe", systemImage: "shield.lefthalf.filled")
                .font(.headline)
                .foregroundStyle(Color.ecInk)
            Text("\u{2022} Meet in a public place, ideally during the day.")
            Text("\u{2022} Check the item works before you pay. Pay in person only.")
            Text("\u{2022} Do not take a damaged or swollen battery. Take it to a collection point.")
            Text("\u{2022} Erase and sign out of any account left on a device.")
        }
        .font(.footnote)
        .foregroundStyle(Color.ecMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    // MARK: Visitor

    @ViewBuilder
    private func visitorSection(_ listing: Listing) -> some View {
        if let request = viewModel.existingRequest(for: listing.id) {
            requestStatusCard(request)
        } else if let block = listing.requestBlock(for: viewModel.user.uid, hasExistingRequest: false, now: viewModel.currentDate) {
            Label(block.message, systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(Color.ecMuted)
        } else {
            Button { showsRequestSheet = true } label: {
                Label(listing.mode == .giveaway ? "Request this item" : "Ask to buy", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.ecGreen, in: Capsule())
            }
        }
    }

    private func requestStatusCard(_ request: ListingRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your request")
                .font(.headline)
                .foregroundStyle(Color.ecInk)
            CommunityBadge(text: request.status.displayName,
                           background: request.status == .accepted ? Color.ecGreenSoft : Color.white)
            switch request.status {
            case .pending:
                Text("The owner chooses who gets the item, so this can take a day or two. You will see the result under My requests.")
                    .font(.subheadline).foregroundStyle(Color.ecMuted)
            case .accepted:
                Text("Accepted! Contact the owner to agree a time and place.")
                    .font(.subheadline).foregroundStyle(Color.ecInk)
                if let url = RequestDraft.normalizedPhone(request.ownerContact).flatMap({ URL(string: "tel:\($0)") }) {
                    Link(destination: url) {
                        Label(request.ownerContact, systemImage: "phone.fill")
                            .font(.headline).foregroundStyle(Color.ecGreen)
                    }
                }
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    // MARK: Owner

    @ViewBuilder
    private func ownerSection(_ listing: Listing) -> some View {
        switch listing.status {
        case .open:
            if listing.shouldSuggestRecycling(now: viewModel.currentDate) {
                recyclingNudge(listing)
            }
            requestsCard(listing)
            Button("Withdraw listing", role: .destructive) { confirmWithdraw = true }
                .frame(maxWidth: .infinity)
        case .reserved:
            reservedCard(listing)
        case .completed:
            Label("Handed over. Thank you for giving it a second life.", systemImage: "checkmark.seal.fill")
                .font(.headline).foregroundStyle(Color.ecGreen)
        case .withdrawn, .expired:
            Label(listing.status == .expired
                  ? "This listing expired. The item is back in My items, ready to recycle."
                  : "You withdrew this listing. The item is back in My items.",
                  systemImage: "arrow.uturn.backward")
                .font(.subheadline).foregroundStyle(Color.ecMuted)
        }
    }

    private func recyclingNudge(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nobody has asked yet", systemImage: "leaf")
                .font(.headline).foregroundStyle(Color.ecInk)
            Text("It has been listed for a week. You can keep waiting, or recycle it responsibly and plan a drop-off now.")
                .font(.subheadline).foregroundStyle(Color.ecInk)
            Button {
                run {
                    if await viewModel.withdraw(listing) { onPlanRecycling() }
                }
            } label: {
                Text("Recycle it instead")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ecGreen, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.ecGreenSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func requestsCard(_ listing: Listing) -> some View {
        let pending = (viewModel.requestsByListing[listing.id] ?? []).filter { $0.status == .pending }
        return VStack(alignment: .leading, spacing: 14) {
            Text("Requests (\(pending.count))")
                .font(.title3.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)
            Text("You choose who gets it. There is no need to pick the first person. Consider what they plan to do with it.")
                .font(.footnote)
                .foregroundStyle(Color.ecMuted)

            if pending.isEmpty {
                Text("No requests yet. Pull down on the previous screen to refresh.")
                    .font(.subheadline).foregroundStyle(Color.ecMuted)
            }
            ForEach(pending) { request in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(request.requesterName).font(.headline).foregroundStyle(Color.ecInk)
                        Spacer()
                        Text(request.createdAt.formatted(.relative(presentation: .named)))
                            .font(.footnote).foregroundStyle(Color.ecMuted)
                    }
                    CommunityBadge(text: request.purpose.displayName)
                    Text(request.message)
                        .font(.subheadline).foregroundStyle(Color.ecInk)
                    HStack(spacing: 12) {
                        Button("Accept") { acceptTarget = request }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.ecGreen)
                        Button("Decline", role: .destructive) {
                            run { _ = await viewModel.decline(request) }
                        }
                        .buttonStyle(.bordered)
                    }
                    .disabled(isWorking)
                    Divider()
                }
                .accessibilityElement(children: .contain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    private func reservedCard(_ listing: Listing) -> some View {
        let accepted = (viewModel.requestsByListing[listing.id] ?? []).first { $0.status == .accepted }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Reserved for \(listing.reservedForName ?? "the person you chose")")
                .font(.title3.bold())
                .foregroundStyle(Color.ecInk)
            Text("They can see your number. Agree a time and place, then mark it as handed over once it has happened.")
                .font(.subheadline).foregroundStyle(Color.ecMuted)

            if let accepted, let url = RequestDraft.normalizedPhone(accepted.contactPhone).flatMap({ URL(string: "tel:\($0)") }) {
                Link(destination: url) {
                    Label("Call \(accepted.contactPhone)", systemImage: "phone.fill")
                        .font(.headline).foregroundStyle(Color.ecGreen)
                }
            }

            Button {
                run { _ = await viewModel.markHandedOver(listing) }
            } label: {
                Text("Mark as handed over")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.ecGreen, in: Capsule())
            }
            .disabled(isWorking)

            Button("They did not show up. Reopen the listing") {
                run { _ = await viewModel.reopen(listing) }
            }
            .font(.subheadline)
            .disabled(isWorking)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    // MARK: Helpers

    private func run(_ work: @escaping () async -> Void) {
        isWorking = true
        Task {
            await work()
            isWorking = false
        }
    }
}

/// Asks the owner for the number to share with the person they are accepting.
private struct AcceptContactSheet: View {
    @Bindable var viewModel: CommunityViewModel
    let listing: Listing
    let request: ListingRequest
    let onDone: () -> Void

    @State private var phone = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Form {
                if let message = viewModel.errorMessage {
                    Section { CommunityMessageBanner(text: message) { viewModel.errorMessage = nil } }
                }
                Section {
                    TextField("Your phone number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("Accept \(request.requesterName)")
                } footer: {
                    Text("Only \(request.requesterName) will see this number, and only because you accepted. Everyone else who asked will be told the item went to someone else.")
                }
            }
            .navigationTitle("Share your contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onDone) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Accept") {
                        isSending = true
                        Task {
                            let success = await viewModel.accept(request, in: listing, ownerContact: phone)
                            isSending = false
                            if success { onDone() }
                        }
                    }
                    .disabled(RequestDraft.normalizedPhone(phone) == nil || isSending)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { viewModel.errorMessage = nil }
    }
}
