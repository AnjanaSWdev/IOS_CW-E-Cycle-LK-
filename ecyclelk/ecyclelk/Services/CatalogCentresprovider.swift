//
//  CatalogCentresprovider.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation
 
struct CatalogCentresProvider: CentresProviding {
    let catalog: CentresCatalog
 
    func fetchCentres() async throws -> [CentreOption] {
        try await MainActor.run {
            try catalog.loadCentres()
                .filter { $0.kind == .ekunuPublicDropoff }          // plans are for places the public can visit
                .map { CentreOption(id: $0.id, name: $0.name, address: $0.address) }
        }
    }
}
