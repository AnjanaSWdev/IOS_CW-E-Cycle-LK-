//
//  CentresView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI
import UIKit
 
/// "Centres" tab: find where to take your e-waste.
struct CentresView: View {
    @Bindable var viewModel: CentresViewModel
    @Bindable var geofence: GeofenceViewModel
 
    @State private var detailCentre: RecyclingCentre?
    @Environment(\.openURL) private var openURL
 
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controls
                content
            }
            .background(Color.ecBackground)
            .navigationTitle("Recycling centres")
            .navigationBarTitleDisplayMode(.large)
            .ecToolbar()
            .searchable(text: $viewModel.searchText, prompt: "Search by name, town or district")
        }
        .onAppear {
            viewModel.load()
            viewModel.refreshLocation()
        }
        .sheet(item: $detailCentre) { centre in
            CentreDetailView(centre: centre, distanceMeters: viewModel.distance(to: centre))
                .presentationDetents([.medium, .large])
        }
    }
 
    // MARK: Controls
 
    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Display", selection: $viewModel.displayMode) {
                ForEach(CentresViewModel.DisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
 
            locationBanner
            CentreAlertsCard(viewModel: geofence)
 
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All items", isSelected: viewModel.categoryFilter == nil) {
                        viewModel.categoryFilter = nil
                    }
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        FilterChip(title: category.displayName,
                                   isSelected: viewModel.categoryFilter == category) {
                            viewModel.categoryFilter = (viewModel.categoryFilter == category) ? nil : category
                        }
                    }
                }
            }
 
            Toggle("Public drop-off points only", isOn: $viewModel.publicDropOffOnly)
                .font(.subheadline)
                .tint(Color.ecGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
 
    @ViewBuilder
    private var locationBanner: some View {
        switch viewModel.locationState {
        case .notAsked:
            banner(text: "Allow location to sort centres by distance from you.",
                   buttonTitle: "Allow location") { viewModel.requestLocation() }
        case .denied:
            banner(text: "Location is off, so distances are hidden. You can turn it on in Settings.",
                   buttonTitle: "Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        case .locating:
            HStack(spacing: 8) {
                ProgressView()
                Text("Finding your location\u{2026}")
                    .font(.footnote)
                    .foregroundStyle(Color.ecMuted)
            }
        case .available:
            Text("Sorted by distance from you")
                .font(.footnote)
                .foregroundStyle(Color.ecMuted)
        }
    }
 
    private func banner(text: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color.ecInk)
            Spacer(minLength: 8)
            Button(buttonTitle, action: action)
                .font(.footnote.bold())
                .buttonStyle(.borderedProminent)
                .tint(Color.ecGreen)
        }
        .padding(12)
        .background(Color.ecGreenSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
 
    // MARK: Content
 
    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage {
            ContentUnavailableView("Couldn\u{2019}t load centres",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text(message))
        } else if viewModel.visibleRows.isEmpty {
            ContentUnavailableView {
                Label("No centres match", systemImage: "magnifyingglass")
            } description: {
                Text("Try a different item type or search.")
            } actions: {
                if viewModel.hasActiveFilters {
                    Button("Clear filters") { viewModel.clearFilters() }
                }
            }
        } else if viewModel.displayMode == .map {
            CentresMapView(rows: viewModel.mappableRows) { detailCentre = $0 }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.visibleRows) { row in
                        Button { detailCentre = row.centre } label: {
                            CentreRowView(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }
}
 
/// Pill used for the category filter.
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.ecInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.ecGreen : Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(isSelected ? 0 : 0.1)))
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
 
