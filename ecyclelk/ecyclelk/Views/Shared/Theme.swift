//
//  Theme.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

/// Colours taken from the Figma prototype (green recycling theme).
/// Light mode only for now; the dark-mode pass is part of the accessibility day.
extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let ecGreen = Color(hex: 0x0B7A43)        // primary buttons, selected chips
    static let ecGreenSoft = Color(hex: 0xD3F0DF)    // unselected chip tray, step badges
    static let ecBackground = Color(hex: 0xEEF8F2)   // screen background
    static let ecInk = Color(hex: 0x10261A)          // main text
    static let ecMuted = Color(hex: 0x4D6256)        // secondary text (kept dark enough for contrast)
    static let ecWarning = Color(hex: 0xFDEBC8)      // "Handle with care" card
    static let ecWarningInk = Color(hex: 0x7A4B00)
}

/// White rounded card used on every screen in the prototype.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.06))
            )
    }
}

extension View {
    func ecCard() -> some View { modifier(CardStyle()) }
}

