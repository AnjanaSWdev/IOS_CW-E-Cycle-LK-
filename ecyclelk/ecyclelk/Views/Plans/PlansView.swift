//
//  PlansView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

/// "Plans" tab: your schedule.
struct PlansView: View {
    @State private var viewModel: PlansViewModel
    @State private var showingNewPlan = false
    @State private var planToComplete: PlanRecord?
    @State private var planToCancel: PlanRecord?
    @Environment(\.openURL) private var openURL

    init(viewModel: PlansViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Turn good intentions into completed recycling activities.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)

                    Button {
                        showingNewPlan = true
                    } label: {
                        Label("New plan", systemImage: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .frame(minHeight: 48)
                            .background(Color.ecGreen, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    if viewModel.remindersDenied { notificationsOffCard }

                    if viewModel.upcomingPlans.isEmpty {
                        ContentUnavailableView(
                            "No plans yet",
                            systemImage: "calendar",
                            description: Text("Tap New plan to schedule a drop-off for your saved items.")
                        )
                    } else {
                        ForEach(Array(viewModel.upcomingPlans.enumerated()), id: \.element.id) { index, plan in
                            PlanCardView(
                                plan: plan,
                                isNext: index == 0,
                                onComplete: { planToComplete = plan },
                                onCancel: { planToCancel = plan }
                            )
                        }
                        if let next = viewModel.nextPlan, next.reminderEnabled {
                            reminderCard(for: next)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationTitle("Your schedule")
            .ecToolbar()
        }
        .onAppear { viewModel.load() }
        .task { await viewModel.loadCentres() }
        .sheet(isPresented: $showingNewPlan) {
            NewPlanView(viewModel: viewModel)
        }
        .confirmationDialog(
            "Mark as recycled?",
            isPresented: Binding(get: { planToComplete != nil }, set: { if !$0 { planToComplete = nil } }),
            titleVisibility: .visible,
            presenting: planToComplete
        ) { plan in
            Button("Mark as recycled") { viewModel.completePlan(plan) }
            Button("Not yet", role: .cancel) {}
        } message: { plan in
            Text("\(plan.itemCount) item(s) will move to your recycling history.")
        }
        .confirmationDialog(
            "Cancel this plan?",
            isPresented: Binding(get: { planToCancel != nil }, set: { if !$0 { planToCancel = nil } }),
            titleVisibility: .visible,
            presenting: planToCancel
        ) { plan in
            Button("Cancel plan", role: .destructive) { viewModel.cancelPlan(plan) }
            Button("Keep plan", role: .cancel) {}
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(get: { viewModel.errorMessage != nil },
                                 set: { if !$0 { viewModel.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Cards

    private func reminderCard(for plan: PlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "bell")
                .foregroundStyle(Color.ecGreen)
                .accessibilityHidden(true)
            Text("Reminder is on").font(.headline).foregroundStyle(Color.ecInk)
            Text("\u{201C}\(PlansViewModel.reminderBody(for: plan))\u{201D}")
                .font(.subheadline)
                .foregroundStyle(Color.ecMuted)
            Text("DELIVERED \(ReminderLead.label(forMinutes: plan.reminderMinutesBefore).uppercased())")
                .font(.caption.bold())
                .foregroundStyle(Color.ecGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.ecGreenSoft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var notificationsOffCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notifications are off", systemImage: "bell.slash")
                .font(.headline)
                .foregroundStyle(Color.ecWarningInk)
            Text("Your plan was saved, but you won't get a reminder. Turn notifications on for E-Cycle LK in Settings.")
                .font(.subheadline)
                .foregroundStyle(Color.ecWarningInk)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .font(.subheadline.bold())
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.ecWarning, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// One plan card. The next plan is shown dark, like the prototype.
struct PlanCardView: View {
    let plan: PlanRecord
    let isNext: Bool
    let onComplete: () -> Void
    let onCancel: () -> Void

    private var primary: Color { isNext ? .white : .ecInk }
    private var secondary: Color { isNext ? Color.white.opacity(0.75) : .ecMuted }
    private var chipBackground: Color { isNext ? Color.white.opacity(0.14) : .ecGreenSoft }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(isNext ? "UPCOMING" : "PLANNED")
                .font(.caption.bold())
                .foregroundStyle(isNext ? Color(hex: 0x7BE3A1) : Color.ecGreen)

            Text(plan.title)
                .font(.title2.bold())
                .foregroundStyle(primary)

            Text("\(plan.itemCount) \(plan.itemCount == 1 ? "item" : "items") · \(plan.type.displayName)")
                .font(.subheadline)
                .foregroundStyle(secondary)

            if !plan.itemNames.isEmpty {
                Text(plan.itemNames.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], alignment: .leading, spacing: 8) {
                chip(plan.start.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                chip(plan.start.formatted(date: .omitted, time: .shortened))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { completeButton; cancelButton }
                VStack(alignment: .leading, spacing: 10) { completeButton; cancelButton }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(isNext ? Color(hex: 0x10261A) : Color.white,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(isNext ? 0 : 0.06))
        )
        .accessibilityElement(children: .contain)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(chipBackground, in: Capsule())
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            Text("Mark as recycled")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(Color.ecGreen, in: Capsule())
        }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Cancel plan")
                .font(.subheadline.bold())
                .foregroundStyle(primary)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .overlay(Capsule().stroke(primary.opacity(0.4)))
        }
    }
}
