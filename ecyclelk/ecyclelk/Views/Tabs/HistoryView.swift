//
//  HistoryView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

/// "History" tab: your recycling impact.
struct HistoryView: View {
    let viewModel: ImpactViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Review completed activities and the positive progress you're making.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)

                    StatCard(value: "\(viewModel.stats.itemsRecorded)", title: "Items recorded",
                             symbol: "shippingbox", tint: Color.ecGreenSoft)
                    StatCard(value: "\(viewModel.stats.itemsRecycled)", title: "Items recycled",
                             symbol: "arrow.3.trianglepath", tint: Color.ecGreenSoft)
                    StatCard(value: "\(viewModel.stats.completionRatePercent)%", title: "Completion rate",
                             symbol: "checkmark", tint: Color.ecGreenSoft)

                    completedActivities
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationTitle("Recycling history")
            .ecToolbar()
        }
        .onAppear { viewModel.load() }
    }

    private var completedActivities: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed activities")
                        .font(.title3.bold())
                        .foregroundStyle(Color.ecInk)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(viewModel.stats.kgRecycledThisYear.formatted(.number.precision(.fractionLength(1)))) kg diverted from landfill")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)
                }
                Spacer(minLength: 8)
                Text("This year")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.ecGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ecGreenSoft, in: Capsule())
            }

            if viewModel.stats.recycledThisYear.isEmpty {
                Text("Nothing recycled yet. When you mark a plan as recycled, it shows up here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)
            } else {
                ForEach(viewModel.stats.recycledThisYear) { item in
                    HStack(spacing: 14) {
                        Image(systemName: item.category.symbolName)
                            .foregroundStyle(Color.ecInk)
                            .frame(width: 48, height: 48)
                            .background(item.category.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.headline).foregroundStyle(Color.ecInk)
                            Text(item.centreName ?? "Recycled")
                                .font(.subheadline)
                                .foregroundStyle(Color.ecMuted)
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 2) {
                            if let date = item.recycledDate {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.ecInk)
                            }
                            Text("Recycled")
                                .font(.footnote.bold())
                                .foregroundStyle(Color.ecGreen)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }
}
