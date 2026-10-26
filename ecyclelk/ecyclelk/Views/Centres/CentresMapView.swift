//
//  CentresMapView.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import SwiftUI
import MapKit
 
/// Map of the centres. Tapping a pin opens the centre's detail sheet.
struct CentresMapView: View {
    let rows: [CentresViewModel.Row]
    let onSelect: (RecyclingCentre) -> Void
 
    private static let sriLanka = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
        span: MKCoordinateSpan(latitudeDelta: 4.6, longitudeDelta: 3.2)
    )
 
    @State private var position: MapCameraPosition = .userLocation(fallback: .region(Self.sriLanka))
    @State private var selection: String?
 
    var body: some View {
        Map(position: $position, selection: $selection) {
            UserAnnotation()
            ForEach(rows) { row in
                if let coordinate = row.centre.coordinate {
                    Marker(row.centre.name, systemImage: "arrow.3.trianglepath", coordinate: coordinate)
                        .tint(row.centre.kind == .ekunuPublicDropoff ? Color.ecGreen : Color.orange)
                        .tag(row.centre.id)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue,
                  let centre = rows.first(where: { $0.id == newValue })?.centre else { return }
            onSelect(centre)
            selection = nil          // so the same pin can be tapped again
        }
        .accessibilityLabel("Map of recycling centres")
        .accessibilityHint("Switch to List for a screen-reader friendly view")
    }
}
