//
//  CentreAlertCard.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import SwiftUI
import UIKit


struct CentreAlertsCard: View {
    @Bindable var viewModel: GeofenceViewModel
    @Environment(\.openURL) private var openURL
    
    var body: some View{
        VStack(alignment: .leading, spacing: 8){
            Toggle(isOn: Binding(get: { viewModel.isEnabled }, set: { viewModel.setEnabled($0)})) {
                
                Label("Alert me near centres", systemImage: "bell.badge")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ecInk)
                
            }
            .tint(Color.ecGreen)
            
            if viewModel.isEnabled {
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(Color.ecMuted)
                    .fixedSize(horizontal: false, vertical: true)
            
            
            if viewModel.state == .needsAlways || viewModel.state == .denied{
                
                Button("Open Settings"){
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url)}
                    
                }.font(.footnote.weight(.semibold))
                .foregroundStyle(Color.ecGreen)
                
            }
        }else{
            Text("Get a notification when you are near a centre that accepts one of your items.")
                .font(.footnote)
                .foregroundStyle(Color.ecMuted)
        }
    }.padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
}

    private var statusText: String {
        
        switch viewModel.state{
        case .off:
            return ""
            
        case .needsAlways:
            return "Set Location to \u{201c}Always\u{201D} in Settings so alerts also work when the app is closed."
        case .denied:
            return "Location is off for this app, so alerts cannot work"
            
        case .noRelevantCentres:
            return "Add an item first. Alerts only cover centres that accept your items."
        case .active(let count):
            return "Watching \(count) nearby \(count == 1 ? "centre" : "centres") that accept your items"
        }
    }

}
