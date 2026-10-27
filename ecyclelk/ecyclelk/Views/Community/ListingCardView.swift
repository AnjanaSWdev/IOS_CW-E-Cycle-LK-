//
//  ListingCardView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI

/// Small pill used for price, condition and status.
struct CommunityBadge: View {
    let text: String
    var background: Color = Color.ecGreenSoft
    var foreground: Color = Color.ecInk

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }
}

/// Banner for errors and confirmations. Shown inline so it never clashes with sheets.
struct CommunityMessageBanner: View {
    let text: String
    var isError = true
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isError ? Color.ecWarningInk : Color.ecGreen)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(isError ? Color.ecWarningInk : Color.ecInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Dismiss message")
        }
        .padding(12)
        .background(isError ? Color.ecWarning : Color.ecGreenSoft,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Filter pill used on the Browse screen.
struct CommunityFilterChip: View {
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

/// One listing in a list.
struct ListingCardView: View {
    let listing: Listing
    let now: Date
    var showsStatus = false

    private var footnote: String {
        guard listing.status == .open else { return listing.district }
        let days = listing.daysLeft(now: now)
        let left = days <= 1 ? "Last day" : "\(days) days left"
        return "\(listing.district) \u{00B7} \(left)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: listing.category.symbolName)
                .font(.title3)
                .foregroundStyle(Color.ecInk)
                .frame(width: 48, height: 48)
                .background(listing.category.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.headline)
                    .foregroundStyle(Color.ecInk)
                    .multilineTextAlignment(.leading)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 6)], alignment: .leading, spacing: 6) {
                    CommunityBadge(text: listing.priceText)
                    CommunityBadge(text: listing.condition.displayName, background: Color.white, foreground: Color.ecInk)
                    if showsStatus {
                        CommunityBadge(text: listing.status.displayName,
                                       background: listing.status == .open || listing.status == .reserved ? Color.ecWarning : Color.ecGreenSoft,
                                       foreground: listing.status == .open || listing.status == .reserved ? Color.ecWarningInk : Color.ecInk)
                    }
                }

                Text(footnote)
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)

                if showsStatus && listing.requestCount > 0 {
                    Text("\(listing.requestCount) request\(listing.requestCount == 1 ? "" : "s")")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.ecGreen)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the listing")
    }
}
