//
//  CentreDetailView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI
import MapKit
 
/// Details for one centre: address, hours, phone, accepted items and directions.
struct CentreDetailView: View {
    let centre: RecyclingCentre
    let distanceMeters: Double?
 
    @Environment(\.dismiss) private var dismiss
 
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
 
                    if centre.needsConfirmation {
                        warning
                    }
 
                    infoCard
 
                    acceptedCard
 
                    if !centre.notes.isEmpty {
                        Text(centre.notes)
                            .font(.footnote)
                            .foregroundStyle(Color.ecMuted)
                    }
                    if !centre.source.isEmpty {
                        Text("Source: \(centre.source)")
                            .font(.footnote)
                            .foregroundStyle(Color.ecMuted)
                    }
 
                    Button(action: openDirections) {
                        Label("Get directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(centre.coordinate == nil ? Color.gray : Color.ecGreen, in: Capsule())
                    }
                    .disabled(centre.coordinate == nil)
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationTitle("Centre details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
 
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(centre.kind.displayName.uppercased())
                .font(.caption.bold())
                .foregroundStyle(Color.ecGreen)
            Text(centre.name)
                .font(.title.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)
            if let distanceMeters {
                Text("\(CentresViewModel.distanceText(distanceMeters)) from you")
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)
            }
        }
    }
 
    private var warning: some View {
        Label("This is a business-focused collector. Please call first to confirm they take public drop-offs and your items.",
              systemImage: "phone.badge.checkmark")
            .font(.subheadline)
            .foregroundStyle(Color.ecWarningInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.ecWarning, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
 
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            infoRow(symbol: "mappin.and.ellipse", title: "Address", text: centre.address)
            infoRow(symbol: "clock", title: "Opening hours",
                    text: centre.openingHours.isEmpty ? "Not published. Call to confirm." : centre.openingHours)
            if let phoneURL = centre.phoneURL {
                Link(destination: phoneURL) {
                    infoRow(symbol: "phone", title: "Phone", text: centre.phone, isLink: true)
                }
            } else {
                infoRow(symbol: "phone", title: "Phone", text: "Not published")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }
 
    private func infoRow(symbol: String, title: String, text: String, isLink: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Color.ecGreen)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.footnote.bold()).foregroundStyle(Color.ecMuted)
                Text(text)
                    .font(.body)
                    .foregroundStyle(isLink ? Color.ecGreen : Color.ecInk)
                    .multilineTextAlignment(.leading)
            }
        }
        .accessibilityElement(children: .combine)
    }
 
    private var acceptedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accepts")
                .font(.title3.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)
 
            let categories = ItemCategory.allCases.filter { centre.accepts($0) }
            if categories.isEmpty {
                Text("Accepted items not listed. Call to confirm.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Label(category.displayName, systemImage: category.symbolName)
                            .font(.subheadline)
                            .foregroundStyle(Color.ecInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(category.tint, in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }
 
    private func openDirections() {
        guard let location = centre.location else { return }
        let item = MKMapItem(location: location, address: nil)
        item.name = centre.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
 
