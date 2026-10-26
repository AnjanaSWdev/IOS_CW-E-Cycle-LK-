//
//  HomeView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

/// "Home" tab: the dashboard.
struct HomeView: View {
    @Environment(AppSession.self) private var session
    let viewModel: ImpactViewModel
    let onAddItem: () -> Void
    let onFindCentre: () -> Void

    private var firstName: String {
        session.user.name.split(separator: " ").first.map(String.init) ?? ""
    }

    private func two(_ number: Int) -> String { String(format: "%02d", number) }

    private func count(_ number: Int, _ noun: String) -> String {
        "\(number) \(noun)\(number == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(firstName.isEmpty ? "WELCOME BACK" : "WELCOME BACK, \(firstName.uppercased())")
                        .font(.caption.bold())
                        .foregroundStyle(Color.ecGreen)

                    Text("Let\u{2019}s give your old tech a better ending.")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.ecInk)
                        .accessibilityAddTraits(.isHeader)

                    Label("\(viewModel.stats.kgRecycled.formatted(.number.precision(.fractionLength(1)))) kg recycled",
                          systemImage: "arrow.3.trianglepath")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.ecInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.ecGreenSoft, in: Capsule())

                    StatCard(value: two(viewModel.stats.activeItems), title: "Active items",
                             subtitle: "\(count(viewModel.stats.addedThisMonth, "item")) added this month",
                             symbol: "shippingbox", tint: Color(hex: 0xD4EEFB))

                    StatCard(value: two(viewModel.upcomingPlans.count), title: "Upcoming plans",
                             subtitle: nextPickupText,
                             symbol: "calendar", tint: Color.ecWarning)

                    StatCard(value: two(viewModel.stats.itemsRecycled), title: "Items recycled",
                             subtitle: "\(viewModel.stats.recycledThisMonth) completed this month",
                             symbol: "arrow.3.trianglepath", tint: Color.ecGreenSoft)

                    Text("Quick actions")
                        .font(.title3.bold())
                        .foregroundStyle(Color.ecInk)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 4)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { addItemButton; findCentreButton }
                        VStack(spacing: 12) { addItemButton; findCentreButton }
                    }
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationBarTitleDisplayMode(.inline)
            .ecToolbar()
        }
        .onAppear { viewModel.load() }
    }

    private var nextPickupText: String {
        guard let plan = viewModel.nextPlan else { return "No plans scheduled" }
        return "Next pickup \(plan.start.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))"
    }

    private var addItemButton: some View {
        Button(action: onAddItem) {
            Label("Add item", systemImage: "plus")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.ecGreen, in: Capsule())
        }
    }

    private var findCentreButton: some View {
        Button(action: onFindCentre) {
            Label("Find a centre", systemImage: "mappin.and.ellipse")
                .font(.headline)
                .foregroundStyle(Color.ecInk)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(0.1)))
        }
    }
}
