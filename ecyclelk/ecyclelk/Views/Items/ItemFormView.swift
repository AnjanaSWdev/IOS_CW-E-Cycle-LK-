//
//  ItemFormView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

/// Add / Edit form (prototype: "Add e-waste item").
struct ItemFormView: View {
    enum Mode {
        case add
        case edit(ItemRecord)
    }

    private enum InputMethod: String, CaseIterable, Identifiable {
        case manual = "Manual entry"
        case smartScan = "Smart scan"
        var id: String { rawValue }
    }

    let mode: Mode
    /// Returns `true` when saving worked, so the sheet can close.
    let onSave: (ItemDraft) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var draft: ItemDraft
    @State private var inputMethod: InputMethod = .manual
    @State private var scanModel = ScanViewModel(classifier: VisionItemClassifier(), items: nil)

    init(mode: Mode, onSave: @escaping (ItemDraft) -> Bool) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add: _draft = State(initialValue: ItemDraft())
        case .edit(let item): _draft = State(initialValue: ItemDraft(record: item))
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Keep a structured record of electronics you plan to recycle.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)

                    if !isEditing {
                        Picker("Input method", selection: $inputMethod) {
                            ForEach(InputMethod.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    switch inputMethod {
                    case .manual: manualForm
                    case .smartScan: smartScanSection
                    }
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationTitle(isEditing ? "Edit item" : "Add e-waste item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave(draft) { dismiss() }
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }

    // MARK: - Manual entry

    private var manualForm: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Item details").font(.title3.bold()).foregroundStyle(Color.ecInk)
                Text("Add the information you know. You can update it later.")
                    .font(.subheadline).foregroundStyle(Color.ecMuted)
            }

            field("Item name") {
                TextField("e.g. Samsung Galaxy S9", text: $draft.name)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .frame(minHeight: 48)
                    .background(Color.ecBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            field("Category") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        ChipButton(title: category.displayName, isSelected: draft.category == category) {
                            selectCategory(category)
                        }
                    }
                }
            }

            field("Condition") {
                HStack(spacing: 8) {
                    ForEach(ItemCondition.allCases, id: \.self) { condition in
                        ChipButton(title: condition.displayName, isSelected: draft.condition == condition) {
                            draft.condition = condition
                        }
                    }
                }
            }

            field("Estimated weight") {
                Stepper(value: $draft.weightKg, in: 0.1...50, step: 0.1) {
                    Text("\(draft.weightKg, format: .number.precision(.fractionLength(1))) kg")
                        .foregroundStyle(Color.ecInk)
                }
                .accessibilityLabel("Estimated weight")
                .accessibilityValue("\(draft.weightKg.formatted(.number.precision(.fractionLength(1)))) kilograms")
            }

            field("Description (optional)") {
                TextField("Add model, age, damage or anything else that may help.",
                          text: $draft.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.ecBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .ecCard()
    }

    private var smartScanSection: some View {
        SmartScanSection(viewModel: scanModel) { category, name, condition in
            // Copy the confirmed result into the form, then show the form so it can be reviewed and saved.
            selectCategory(category)
            if draft.name.trimmingCharacters(in: .whitespaces).isEmpty { draft.name = name }
            draft.condition = condition
            if draft.notes.isEmpty { draft.notes = "Added with Smart scan" }
            inputMethod = .manual
        }
    }

    // MARK: - Helpers

    private func selectCategory(_ category: ItemCategory) {
        // When adding, keep the suggested weight in step with the category.
        let weightWasDefault = draft.weightKg == draft.category.defaultWeightKg
        draft.category = category
        if !isEditing && weightWasDefault {
            draft.weightKg = category.defaultWeightKg
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold()).foregroundStyle(Color.ecInk)
            content()
        }
    }
}
