//
//  CenterRowView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI

/// One centre in the list

struct CentreRowView: View {
    
    let row: CentresViewModel.Row
    
    private var centre: RecyclingCentre { row.centre }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14){
            Image(systemName: centre.kind == .ekunuPublicDropoff ? "mappin.and.ellipse" : "building.2")
                .font(.title3)
                .foregroundStyle(Color.ecInk)
                .frame(width: 48, height: 48)
                .background(centre.kind == .ekunuPublicDropoff ? Color.ecGreenSoft : Color.ecWarning,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4){
                Text(centre.name)
                    .font(.headline)
                    .foregroundStyle(Color.ecInk)
                    .multilineTextAlignment(.leading)
                Text(centre.address)
                    .font(.subheadline)
                    .foregroundStyle(Color.ecMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 6){
                    Text(centre.kind.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(Color.ecGreen)
                    if centre.needsConfirmation {
                        Text("Call first")
                            .font(.caption.bold())
                            .foregroundStyle(Color.ecWarningInk)
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer(minLength: 8)
            
            if let meters = row.distanceMeters {
                Text(CentresViewModel.distanceText(meters))
                    .font(.subheadline.bold())
                        .foregroundStyle(Color.ecInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.ecGreenSoft, in: Capsule())
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens details")
    }
}
