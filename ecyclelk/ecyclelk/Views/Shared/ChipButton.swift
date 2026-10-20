//
//  ChipButton.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

/// Pill-shaped selectable option, used for category filters and form choices.
struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.ecInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(minHeight: 44)   // minimum touch target
                .background(
                    Capsule().fill(isSelected ? Color.ecGreen : Color.ecGreenSoft)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
