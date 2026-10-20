//
//  ItemRowView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

/// One card in the "Saved items" list.
struct ItemRowView: View {
    let item: ItemRecord

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.category.symbolName)
                .font(.title3)
                .foregroundStyle(Color.ecInk)
                .frame(width: 48, height: 48)
                .background(item.category.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.ecInk)
                Text("\(item.category.displayName) · \(item.condition.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)
            }
            Spacer(minLength: 0)
        }
        .ecCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the disposal guide")
    }
}
