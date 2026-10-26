//
//  NewPlanView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

/// "Plan a drop-off" form.
struct NewPlanView: View {
    let viewModel: PlansViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draft = PlanDraft(start: NewPlanView.defaultStart())
    @State private var isSaving = false

    /// Tomorrow at 10:00.
    private static func defaultStart() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Choose what you're taking, where you're going and when.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)

                    VStack(alignment: .leading, spacing: 24) {
                        section("1. Select items") { itemsDropdown }
                        section("2. Select a centre") { centreDropdown }
                        section("3. Choose a date and time") {
                            DatePicker("Date and time", selection: $draft.start, in: Date()...,
                                       displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        }
                        section("4. Reminder") { reminderControls }

                        if let problem = draft.firstProblem() {
                            Text(problem.errorDescription ?? "")
                                .font(.footnote)
                                .foregroundStyle(Color.ecMuted)
                        }
                    }
                    .ecCard()
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationTitle("Plan a drop-off")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(draft.firstProblem() != nil || isSaving)
                }
            }
        }
        .task { viewModel.load() }
    }

    // MARK: - Dropdowns

    /// Multi-select menu. It stays open while you tick items.
    @ViewBuilder
    private var itemsDropdown: some View {
        if viewModel.availableItems.isEmpty {
            Text("You have no saved items to plan. Add an item in My items first.")
                .font(.subheadline)
                .foregroundStyle(Color.ecMuted)
        } else {
            Menu {
                ForEach(viewModel.availableItems) { item in
                    Toggle(item.name, isOn: itemBinding(for: item.id))
                }
            } label: {
                dropdownLabel(title: "Items", text: itemsSummary, isPlaceholder: draft.itemIDs.isEmpty)
            }
            .menuActionDismissBehavior(.disabled)

            if !selectedItemNames.isEmpty {
                Text(selectedItemNames.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundStyle(Color.ecMuted)
            }
        }
    }

    private var centreDropdown: some View {
        Menu {
            ForEach(viewModel.centres) { centre in
                Button {
                    draft.centreID = centre.id
                    draft.centreName = centre.name
                } label: {
                    if draft.centreID == centre.id {
                        Label(centre.name, systemImage: "checkmark")
                    } else {
                        Text(centre.name)
                    }
                }
            }
        } label: {
            dropdownLabel(title: "Centre",
                          text: draft.centreName ?? "Choose a centre",
                          isPlaceholder: draft.centreName == nil)
        }
    }

    @ViewBuilder
    private var reminderControls: some View {
        Toggle("Remind me before the visit", isOn: $draft.reminderEnabled)
            .tint(Color.ecGreen)
        if draft.reminderEnabled {
            Picker("Remind me", selection: $draft.reminderMinutesBefore) {
                ForEach(ReminderLead.allCases) { lead in
                    Text(lead.displayName).tag(lead.rawValue)
                }
            }
        }
    }

    // MARK: - Helpers

    /// The field-style button that opens a dropdown.
    private func dropdownLabel(title: String, text: String, isPlaceholder: Bool) -> some View {
        HStack {
            Text(text)
                .foregroundStyle(isPlaceholder ? Color.ecMuted : Color.ecInk)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.ecMuted)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(Color.ecBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(text)
        .accessibilityHint("Opens a menu")
    }

    private var selectedItemNames: [String] {
        viewModel.availableItems.filter { draft.itemIDs.contains($0.id) }.map(\.name)
    }

    private var itemsSummary: String {
        switch draft.itemIDs.count {
        case 0: return "Choose items"
        case 1: return selectedItemNames.first ?? "1 item selected"
        default: return "\(draft.itemIDs.count) items selected"
        }
    }

    private func itemBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { draft.itemIDs.contains(id) },
            set: { isOn in
                if isOn { draft.itemIDs.insert(id) } else { draft.itemIDs.remove(id) }
            }
        )
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func save() {
        isSaving = true
        Task {
            if await viewModel.createPlan(draft) { dismiss() }
            isSaving = false
        }
    }
}
