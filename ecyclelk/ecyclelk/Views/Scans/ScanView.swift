//
//  ScanView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import SwiftUI
import PhotosUI

/// "Smart scan": take or choose a photo, check the suggested category, save the item.
struct ScanView: View {
    @Bindable var viewModel: ScanViewModel
    let onClose: () -> Void
    let onSaved: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showsCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let message = viewModel.errorMessage {
                        ScanMessageBanner(text: message) { viewModel.errorMessage = nil }
                    }

                    photoArea
                    sourceButtons

                    switch viewModel.phase {
                    case .idle:
                        Text("Take a photo of your device, or choose one from your library. The model runs on this phone, so your photo is never uploaded.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ecMuted)
                    case .classifying:
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Looking at your photo\u{2026}")
                                .foregroundStyle(Color.ecMuted)
                        }
                        .accessibilityElement(children: .combine)
                    case .failed(let message):
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Color.ecWarningInk)
                    case .done:
                        resultSection
                    }
                }
                .padding(16)
            }
            .background(Color.ecBackground)
            .navigationTitle("Smart scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await viewModel.classify(imageData: data)
                }
                pickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showsCamera) {
            CameraPicker { data in
                Task { await viewModel.classify(imageData: data) }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: Photo

    @ViewBuilder
    private var photoArea: some View {
        if let data = viewModel.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityLabel("Photo of your item")
        } else {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(Color.ecGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color.ecGreenSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)
        }
    }

    private var sourceButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { cameraButton; libraryButton }
            VStack(spacing: 12) { cameraButton; libraryButton }
        }
    }

    @ViewBuilder
    private var cameraButton: some View {
        if CameraPicker.isAvailable {
            Button { showsCamera = true } label: {
                Label("Take photo", systemImage: "camera")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.ecGreen, in: Capsule())
            }
        }
    }

    private var libraryButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label("Choose photo", systemImage: "photo.on.rectangle")
                .font(.headline)
                .foregroundStyle(CameraPicker.isAvailable ? Color.ecInk : Color.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(CameraPicker.isAvailable ? Color.white : Color.ecGreen, in: Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(CameraPicker.isAvailable ? 0.1 : 0)))
        }
    }

    // MARK: Result

    @ViewBuilder
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(headline)
                .font(.title3.bold())
                .foregroundStyle(Color.ecInk)
                .accessibilityAddTraits(.isHeader)

            Text("Tap the right category if the first guess is wrong.")
                .font(.footnote)
                .foregroundStyle(Color.ecMuted)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(viewModel.alternatives) { result in
                    suggestionChip(result)
                }
            }

            Menu {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Button {
                        viewModel.select(category)
                    } label: {
                        Label(category.displayName, systemImage: category.symbolName)
                    }
                }
            } label: {
                Label("Other category", systemImage: "list.bullet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ecGreen)
            }

            Divider()

            TextField("Item name", text: $viewModel.itemName)
                .textFieldStyle(.roundedBorder)

            Picker("Condition", selection: $viewModel.condition) {
                ForEach(ItemCondition.allCases, id: \.self) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }

            Button {
                if viewModel.save() { onSaved() }
            } label: {
                Text("Add to My items")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(viewModel.canSave ? Color.ecGreen : Color.gray, in: Capsule())
            }
            .disabled(!viewModel.canSave)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
    }

    private var headline: String {
        guard let top = viewModel.topSuggestion else { return "" }
        switch viewModel.confidence {
        case .high: return "This looks like \(top.category.displayName.lowercased())"
        case .medium: return "Probably \(top.category.displayName.lowercased()). Please check."
        case .low, .none: return "I\u{2019}m not sure. Choose the closest match."
        }
    }

    private func suggestionChip(_ result: ClassificationResult) -> some View {
        let isSelected = viewModel.selectedCategory == result.category
        return Button {
            viewModel.select(result.category)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: result.category.symbolName)
                Text(result.category.displayName)
                Spacer(minLength: 4)
                Text(result.percentText).font(.footnote)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.ecInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.ecGreen : result.category.tint, in: Capsule())
        }
        .accessibilityLabel("\(result.category.displayName), \(result.percentText) match")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Inline message banner (kept here so Smart scan has no dependency on the Community files).
struct ScanMessageBanner: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.ecWarningInk)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.ecWarningInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) { Image(systemName: "xmark") }
                .accessibilityLabel("Dismiss message")
        }
        .padding(12)
        .background(Color.ecWarning, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
