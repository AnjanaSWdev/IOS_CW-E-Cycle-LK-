//
//  ScanTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-27.
//

import Foundation
import Testing
@testable import ecyclelk

// MARK: - Fakes

@MainActor
private final class FakeClassifier: ItemClassifying {
    var results: [ClassificationResult] = []
    var error: Error?
    private(set) var callCount = 0

    func classify(imageData: Data) async throws -> [ClassificationResult] {
        callCount += 1
        if let error { throw error }
        return results
    }
}

@MainActor
private final class FakeScanItems: ItemsServiceProtocol {
    private(set) var added: [(draft: ItemDraft, ownerUID: String)] = []
    var failWith: Error?

    func fetchItems(ownerUID: String) throws -> [ItemRecord] { [] }

    @discardableResult
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord {
        if let failWith { throw failWith }
        added.append((draft, ownerUID))
        return ItemRecord(id: UUID(), name: draft.trimmedName, category: draft.category, condition: draft.condition,
                          notes: draft.trimmedNotes, weightKg: draft.weightKg, dateAdded: Date(), status: .saved)
    }

    func updateItem(id: UUID, with draft: ItemDraft) throws {}
    func deleteItem(id: UUID) throws {}
}

private func results(_ pairs: (ItemCategory, Double)...) -> [ClassificationResult] {
    pairs.map { ClassificationResult(category: $0.0, confidence: $0.1) }
}

@MainActor
private func makeViewModel(_ classifier: FakeClassifier, _ items: FakeScanItems? = nil) -> ScanViewModel {
    ScanViewModel(classifier: classifier, items: items ?? FakeScanItems(), ownerUID: "user-1")
}
private let photo = Data([1, 2, 3])

// MARK: - Tests

@MainActor
struct ScanViewModelTests {

    @Test func aConfidentGuessIsPreselectedAndNamed() async {
        let classifier = FakeClassifier()
        classifier.results = results((.laptops, 0.91), (.monitors, 0.06), (.televisions, 0.03))
        let viewModel = makeViewModel(classifier)

        await viewModel.classify(imageData: photo)

        #expect(viewModel.phase == .done)
        #expect(viewModel.confidence == .high)
        #expect(viewModel.selectedCategory == .laptops)
        #expect(viewModel.itemName == ItemCategory.laptops.displayName)
        #expect(viewModel.canSave)
        #expect(viewModel.alternatives.count == 3)
    }

    @Test func aMediumGuessIsPreselectedButFlagged() async {
        let classifier = FakeClassifier()
        classifier.results = results((.batteries, 0.62), (.accessories, 0.3))
        let viewModel = makeViewModel(classifier)
        await viewModel.classify(imageData: photo)
        #expect(viewModel.confidence == .medium)
        #expect(viewModel.selectedCategory == .batteries)
    }

    @Test func aLowConfidenceGuessMakesThePersonChoose() async {
        let classifier = FakeClassifier()
        classifier.results = results((.printers, 0.34), (.monitors, 0.3), (.laptops, 0.2))
        let viewModel = makeViewModel(classifier)

        await viewModel.classify(imageData: photo)

        #expect(viewModel.confidence == .low)
        #expect(viewModel.selectedCategory == nil)
        #expect(!viewModel.canSave)

        viewModel.select(.monitors)
        #expect(viewModel.canSave)
    }

    @Test func changingTheCategoryIsRecordedAndRenamesAutomaticNames() async {
        let classifier = FakeClassifier()
        classifier.results = results((.laptops, 0.9), (.monitors, 0.05))
        let viewModel = makeViewModel(classifier)
        await viewModel.classify(imageData: photo)
        #expect(!viewModel.wasOverridden)

        viewModel.select(.monitors)

        #expect(viewModel.wasOverridden)
        #expect(viewModel.selectedCategory == .monitors)
        #expect(viewModel.itemName == ItemCategory.monitors.displayName)
    }

    @Test func aNameTheUserTypedIsNeverOverwritten() async {
        let classifier = FakeClassifier()
        classifier.results = results((.laptops, 0.9), (.monitors, 0.05))
        let viewModel = makeViewModel(classifier)
        await viewModel.classify(imageData: photo)

        viewModel.itemName = "Dad's old Dell"
        viewModel.select(.monitors)

        #expect(viewModel.itemName == "Dad's old Dell")
    }

    @Test func savingCreatesTheItemWithTheChosenValues() async {
        let classifier = FakeClassifier()
        classifier.results = results((.cameras, 0.88))
        let items = FakeScanItems()
        let viewModel = makeViewModel(classifier, items)
        await viewModel.classify(imageData: photo)
        viewModel.itemName = "  Canon 600D  "
        viewModel.condition = .damaged

        #expect(viewModel.save())

        #expect(items.added.count == 1)
        #expect(items.added[0].ownerUID == "user-1")
        #expect(items.added[0].draft.trimmedName == "Canon 600D")
        #expect(items.added[0].draft.category == .cameras)
        #expect(items.added[0].draft.condition == .damaged)
        #expect(items.added[0].draft.weightKg == ItemCategory.cameras.defaultWeightKg)
    }

    @Test func youCannotSaveWithoutACategoryOrName() async {
        let classifier = FakeClassifier()
        classifier.results = results((.printers, 0.2))
        let items = FakeScanItems()
        let viewModel = makeViewModel(classifier, items)
        await viewModel.classify(imageData: photo)
        #expect(!viewModel.save())

        viewModel.select(.printers)
        viewModel.itemName = "   "
        #expect(!viewModel.canSave)
        #expect(items.added.isEmpty)
    }

    @Test func classifierErrorsBecomeAMessage() async {
        let classifier = FakeClassifier()
        classifier.error = ClassifierError.modelMissing
        let viewModel = makeViewModel(classifier)
        await viewModel.classify(imageData: photo)
        #expect(viewModel.phase == .failed(ClassifierError.modelMissing.errorDescription ?? ""))
    }

    @Test func anEmptyAnswerIsAFailureNotACrash() async {
        let viewModel = makeViewModel(FakeClassifier())
        await viewModel.classify(imageData: photo)
        if case .failed = viewModel.phase {} else { Issue.record("expected a failed phase") }
    }

    @Test func aSaveFailureShowsAnErrorAndKeepsTheForm() async {
        let classifier = FakeClassifier()
        classifier.results = results((.laptops, 0.9))
        let items = FakeScanItems()
        items.failWith = ItemsServiceError.notFound
        let viewModel = makeViewModel(classifier, items)
        await viewModel.classify(imageData: photo)

        #expect(!viewModel.save())
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.selectedCategory == .laptops)
    }

    @Test func resetClearsEverything() async {
        let classifier = FakeClassifier()
        classifier.results = results((.laptops, 0.9))
        let viewModel = makeViewModel(classifier)
        await viewModel.classify(imageData: photo)
        viewModel.reset()
        #expect(viewModel.phase == .idle)
        #expect(viewModel.suggestions.isEmpty)
        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.imageData == nil)
    }
}

@MainActor
struct ClassifierLabelTests {
    @Test func everyAppCategoryNameIsRecognised() {
        for category in ItemCategory.allCases {
            #expect(ClassifierLabels.categories(for: category.rawValue) == [category])
        }
    }

    @Test func aMergedDisplaysLabelOffersBothMonitorAndTelevision() {
        #expect(ClassifierLabels.categories(for: "displays") == [.monitors, .televisions])
    }

    @Test func unknownLabelsAreIgnored() {
        #expect(ClassifierLabels.categories(for: "toaster").isEmpty)
    }

    @Test func percentTextIsRounded() {
        #expect(ClassificationResult(category: .laptops, confidence: 0.876).percentText == "88%")
    }
}
