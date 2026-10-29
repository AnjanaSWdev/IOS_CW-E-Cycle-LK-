//
//  CommunityView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI

struct ListingRoute: Hashable {
    let id: String
}

/// Community: give away or sell items that still have life in them, or ask for one you can use or repair.
struct CommunityView: View {
    @Bindable var viewModel: CommunityViewModel
    var onClose: (() -> Void)? = nil
    let onPlanRecycling: () -> Void

    @State private var path: [ListingRoute] = []
    @State private var showsNewListing = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Picker("Section", selection: $viewModel.section) {
                    ForEach(CommunityViewModel.Section.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                content
            }
            .background(Color.ecBackground)
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if let onClose {
                        Button("Close", action: onClose)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showsNewListing = true } label: {
                        Label("List an item", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: ListingRoute.self) { route in
                ListingDetailView(viewModel: viewModel, listingID: route.id, onPlanRecycling: {
                    onPlanRecycling()
                })
            }
        }
        .task { await viewModel.refresh() }
        .sheet(isPresented: $showsNewListing) {
            NewListingView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.section {
        case .browse: browse
        case .mine: mine
        case .requests: requests
        }
    }

    // MARK: Browse

    private var browse: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                banners
                Label("Prices and handovers are agreed between users. E-Cycle LK does not handle payments.",
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Color.ecMuted)

                filters

                if viewModel.visibleFeed.isEmpty {
                    emptyBrowse
                } else {
                    ForEach(viewModel.visibleFeed) { listing in
                        NavigationLink(value: ListingRoute(id: listing.id)) {
                            ListingCardView(listing: listing, now: viewModel.currentDate)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .refreshable { await viewModel.refresh() }
        .searchable(text: $viewModel.searchText, prompt: "Search items")
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CommunityFilterChip(title: "All items", isSelected: viewModel.categoryFilter == nil) {
                        viewModel.categoryFilter = nil
                    }
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        CommunityFilterChip(title: category.displayName,
                                            isSelected: viewModel.categoryFilter == category) {
                            viewModel.categoryFilter = viewModel.categoryFilter == category ? nil : category
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                CommunityFilterChip(title: "Free", isSelected: viewModel.modeFilter == .giveaway) {
                    viewModel.modeFilter = viewModel.modeFilter == .giveaway ? nil : .giveaway
                }
                CommunityFilterChip(title: "For sale", isSelected: viewModel.modeFilter == .sale) {
                    viewModel.modeFilter = viewModel.modeFilter == .sale ? nil : .sale
                }
                Menu {
                    Button("All districts") { viewModel.districtFilter = "" }
                    ForEach(SriLankaDistricts.all, id: \.self) { district in
                        Button {
                            viewModel.districtFilter = district
                        } label: {
                            if viewModel.districtFilter == district {
                                Label(district, systemImage: "checkmark")
                            } else {
                                Text(district)
                            }
                        }
                    }
                } label: {
                    Label(viewModel.districtFilter.isEmpty ? "All districts" : viewModel.districtFilter,
                          systemImage: "mappin.and.ellipse")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.districtFilter.isEmpty ? Color.ecInk : Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.districtFilter.isEmpty ? Color.white : Color.ecGreen, in: Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(viewModel.districtFilter.isEmpty ? 0.1 : 0)))
                }
                .accessibilityLabel("District filter")
            }
        }
    }

    private var emptyBrowse: some View {
        ContentUnavailableView {
            Label(viewModel.isLoading ? "Loading\u{2026}" : "Nothing here yet", systemImage: "shippingbox")
        } description: {
            Text(viewModel.hasActiveFilters
                 ? "No listings match your filters."
                 : "Be the first to list a working or repairable item.")
        } actions: {
            if viewModel.hasActiveFilters {
                Button("Clear filters") { viewModel.clearFilters() }
            }
        }
    }

    // MARK: My listings

    private var mine: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                banners
                if viewModel.myListings.isEmpty {
                    ContentUnavailableView {
                        Label("No listings yet", systemImage: "tag")
                    } description: {
                        Text("Items that still work, or could be repaired, are worth more to someone else than to a recycler.")
                    } actions: {
                        Button("List an item") { showsNewListing = true }
                    }
                } else {
                    ForEach(viewModel.myListings) { listing in
                        NavigationLink(value: ListingRoute(id: listing.id)) {
                            ListingCardView(listing: listing, now: viewModel.currentDate, showsStatus: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: My requests

    private var requests: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                banners
                if viewModel.myRequests.isEmpty {
                    ContentUnavailableView("No requests yet", systemImage: "hand.raised",
                                           description: Text("Browse the community and ask for an item you could use or repair."))
                } else {
                    ForEach(viewModel.myRequests) { request in
                        MyRequestRow(request: request) {
                            Task { _ = await viewModel.withdrawRequest(request) }
                        }
                    }
                }
            }
            .padding(16)
        }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var banners: some View {
        if let message = viewModel.errorMessage {
            CommunityMessageBanner(text: message) { viewModel.errorMessage = nil }
        }
        if let notice = viewModel.noticeMessage {
            CommunityMessageBanner(text: notice, isError: false) { viewModel.noticeMessage = nil }
        }
    }
}

/// One request you have sent.
private struct MyRequestRow: View {
    let request: ListingRequest
    let onWithdraw: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(request.listingTitle)
                    .font(.headline)
                    .foregroundStyle(Color.ecInk)
                Spacer(minLength: 8)
                CommunityBadge(text: request.status.displayName,
                               background: request.status == .accepted ? Color.ecGreenSoft : Color.white)
            }
            Text(request.purpose.displayName)
                .font(.subheadline)
                .foregroundStyle(Color.ecMuted)

            if request.status == .accepted {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The owner accepted your request. Call or message them to agree a time and a safe place to meet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecInk)
                    if let url = RequestDraft.normalizedPhone(request.ownerContact).flatMap({ URL(string: "tel:\($0)") }) {
                        Link(destination: url) {
                            Label(request.ownerContact, systemImage: "phone.fill")
                                .font(.headline)
                                .foregroundStyle(Color.ecGreen)
                        }
                    }
                }
            }
            if request.status == .pending {
                Button("Withdraw request", role: .destructive, action: onWithdraw)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
        .accessibilityElement(children: .contain)
    }
}
