//
//  StatCard.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct StatCard: View {
    let value: String
    let title: String
    var subtitle: String? = nil
    let symbol: String
    let tint: Color
    
    var body: some View {
        HStack(alignment: .top){
            VStack(alignment: .leading, spacing: 6){
                Text(value)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ecInk)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.ecInk)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.ecMuted)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.ecInk)
                .frame(width: 48, height: 48)
                .background(tint, in:RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            
                
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
        .accessibilityElement(children: .combine)
    }
}
