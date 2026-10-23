//
//  AvatarView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

/// Round initials badge, like the "AM" in the prototype.
struct AvatarView: View {
    let initials: String
    var size: CGFloat = 36

    var body: some View {
        Text(initials)
            .font(size >= 56 ? .title2.bold() : .footnote.bold())
            .foregroundStyle(Color.ecWarningInk)
            .frame(width: size, height: size)
            .background(Color(hex: 0xF3D3A3), in: Circle())
            .accessibilityHidden(true)
    }
}
