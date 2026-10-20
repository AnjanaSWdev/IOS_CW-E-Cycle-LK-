//
//  DisposalGuideView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

/// Disposal guide for one saved item (prototype: "Disposal Guide").
struct DisposalGuideView: View {
    let item: ItemRecord

    private var guide: DisposalGuide {
        DisposalGuide.guide(for: item.category, condition: item.condition)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Recommended handling for \(item.category.displayName.lowercased()).")
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)

                processCard

                if let warning = guide.warning {
                    warningCard(warning)
                }

                Text(DisposalGuide.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(Color.ecMuted)
            }
            .padding(16)
        }
        .background(Color.ecBackground)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var processCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: item.category.symbolName)
                    .font(.title3)
                    .foregroundStyle(Color.ecInk)
                    .frame(width: 48, height: 48)
                    .background(item.category.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(item.category.displayName).font(.headline).foregroundStyle(Color.ecInk)
                    Text(item.condition.displayName).font(.subheadline).foregroundStyle(Color.ecMuted)
                }
            }
            .accessibilityElement(children: .combine)

            Text("Recommended process")
                .font(.title3.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(guide.steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    Text(String(format: "%02d", index + 1))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.ecGreen)
                        .frame(width: 40, height: 40)
                        .background(Color.ecGreenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title).font(.headline).foregroundStyle(Color.ecInk)
                        Text(step.detail).font(.subheadline).foregroundStyle(Color.ecMuted)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1). \(step.title). \(step.detail)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    private func warningCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Handle with care", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(Color.ecWarningInk)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.ecWarningInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.ecWarning, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
