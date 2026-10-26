//
//  Centrescatalog.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation

@MainActor
protocol CentresCatalog{
    func loadCentres() throws -> [RecyclingCentre]
}

enum CentresCatalogError: LocalizedError {
    
    case fileMissing
    case noCentres
    
    var errorDescription: String? {
        
        switch self {
        case .fileMissing: return "The centres list(centers.csv) is missing from the app."
        case .noCentres: return "The centres list is empty"
        }
    }
}

/// Reads centers.csv from the app bundle. Works offline.
struct BundledCentresCatalog: CentresCatalog {
    var bundle: Bundle = .main
    var resourceName = "centres"
    
    func loadCentres() throws -> [RecyclingCentre] {
    
        guard let url = bundle.url(forResource: resourceName, withExtension: "csv") else{
            throw CentresCatalogError .fileMissing
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        let centres = CentreCSVParser.parseCentres(from: text)
        guard !centres.isEmpty else {
            throw CentresCatalogError.noCentres }
        
        
        #if DEBUG
        for centre in centres where !centre.hasPlausibleSriLankanCoordinate {
            print("CHECK centres.csv: \(centre.id) \(centre.name) has missing or implausible coordinates "
            + "(\(centre.latitude.map { String($0) } ?? "blank"), \(centre.longitude.map { String($0) } ?? "blank"))")
        }
        #endif
        return centres
    }
}
