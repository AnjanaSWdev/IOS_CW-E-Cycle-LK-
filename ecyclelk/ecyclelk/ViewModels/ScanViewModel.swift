//
//  ScanViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import Foundation
import Observation

/// Smart scan: photo in, category suggestion out, the person confirms or changes it, then the item is saved.
@MainActor
@Observable
final class ScanViewModel {

    enum Phase: Equatable {
        case idle
        case classifying
        case done
        case failed(String)
    }

    enum Confidence: Equatable {
        case high, medium, low
    }

    static let highThreshold = 0.75
    static let lowThreshold = 0.5

    private(set) var phase: Phase = .idle
    private(set) var suggestions: [ClassificationResult] = []
    private(set) var imageData: Data?
    /// True if the person chose a different category from the model's top guess.
    private(set) var wasOverridden = false

    var selectedCategory: ItemCategory?
    var itemName = ""
    var condition: ItemCondition = .working
    var errorMessage: String?

    private let classifier: ItemClassifying
    /// Nil when Smart scan is used inside the Add item form: that form does the saving.
    private let items: ItemsServiceProtocol?
    private let ownerUID: String
    private var automaticName = ""

    init(classifier: ItemClassifying, items: ItemsServiceProtocol?, ownerUID: String = "local") {
        self.classifier = classifier
        self.items = items
        self.ownerUID = ownerUID
    }

    // MARK: - What the screen shows

    var topSuggestion: ClassificationResult? { suggestions.first }

    var confidence: Confidence? {
        guard let top = topSuggestion else { return nil }
        if top.confidence >= Self.highThreshold { return .high }
        if top.confidence >= Self.lowThreshold { return .medium }
        return .low
    }

    /// The three best guesses, shown as quick choices.
    var alternatives: [ClassificationResult] { Array(suggestions.prefix(3)) }

    var trimmedName: String { itemName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canSave: Bool {
        phase == .done && selectedCategory != nil && !trimmedName.isEmpty
    }

    // MARK: - Actions

    func classify(imageData: Data) async {
        reset()
        self.imageData = imageData
        phase = .classifying
        do {
            let results = try await classifier.classify(imageData: imageData)
            guard !results.isEmpty else {
                phase = .failed("I could not tell what this is. Try a clearer photo of the whole item.")
                return
            }
            suggestions = results
            phase = .done
            // Only pre-select when the model is reasonably sure; otherwise the person must choose.
            if confidence != .low, let top = topSuggestion {
                applySelection(top.category)
            }
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// The person picked a category (a suggestion chip or "Other").
    func select(_ category: ItemCategory) {
        applySelection(category)
        wasOverridden = category != topSuggestion?.category
    }

    func save() -> Bool {
        guard canSave, let category = selectedCategory, let items else { return false }
        let draft = ItemDraft(name: trimmedName,
                              category: category,
                              condition: condition,
                              notes: "Added with Smart scan",
                              weightKg: category.defaultWeightKg)
        do {
            try items.addItem(draft, ownerUID: ownerUID)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        phase = .idle
        suggestions = []
        imageData = nil
        wasOverridden = false
        selectedCategory = nil
        itemName = ""
        automaticName = ""
        condition = .working
        errorMessage = nil
    }

    // MARK: - Helpers

    private func applySelection(_ category: ItemCategory) {
        selectedCategory = category
        // Fill the name for the person unless they have already typed their own.
        if itemName.isEmpty || itemName == automaticName {
            automaticName = category.displayName
            itemName = automaticName
        }
    }
}
