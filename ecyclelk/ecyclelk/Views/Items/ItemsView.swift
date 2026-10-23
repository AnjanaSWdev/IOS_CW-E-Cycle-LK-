//
//  ItemsView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

/// "My items" tab: search, category filter, list, add / edit / delete.
struct ItemsView: View {
    @State private var viewModel: ItemsViewModel
    @State private var formTarget: FormTarget?
    @State private var itemPendingDelete: ItemRecord?

    init(viewModel: ItemsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                header
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if viewModel.filteredItems.isEmpty {
                    emptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.filteredItems) { item in
                        NavigationLink(value: item) {
                            ItemRowView(item: item)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                itemPendingDelete = item
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                formTarget = .edit(item)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ecBackground)
            .navigationTitle("Saved items")
            .ecToolbar()
            .navigationDestination(for: ItemRecord.self) { item in
                DisposalGuideView(item: item)
            }
        }
        .task { viewModel.load() }
        .sheet(item: $formTarget) { target in
            switch target {
            case .add:
                ItemFormView(mode: .add) { draft in viewModel.add(draft) }
            case .edit(let item):
                ItemFormView(mode: .edit(item)) { draft in viewModel.update(item, with: draft) }
            }
        }
        .confirmationDialog(
            "Delete this item?",
            isPresented: Binding(
                get: { itemPendingDelete != nil },
                set: { if !$0 { itemPendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: itemPendingDelete
        ) { item in
            Button("Delete \(item.name)", role: .destructive) {
                viewModel.delete(item)
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search, review and prepare your unwanted electronics for responsible disposal.")
                .font(.subheadline)
                .foregroundStyle(Color.ecMuted)

            Button {
                formTarget = .add
            } label: {
                Label("Add item", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(minHeight: 48)
                    .background(Color.ecGreen, in: Capsule())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.ecMuted)
                    .accessibilityHidden(true)
                TextField("Search saved items...", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityLabel("Search saved items")
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.ecMuted)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.08)))

            categoryChips
        }
        .padding(.vertical, 4)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChipButton(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    ChipButton(
                        title: category.displayName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(6)
        }
        .background(Color.ecGreenSoft.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.hasNoItemsAtAll {
            ContentUnavailableView(
                "No items yet",
                systemImage: "shippingbox",
                description: Text("Tap Add item to record the first electronic item you want to recycle.")
            )
        } else {
            ContentUnavailableView.search(text: viewModel.searchText)
        }
    }
}

private enum FormTarget: Identifiable {
    case add
    case edit(ItemRecord)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return item.id.uuidString
        }
    }
}
