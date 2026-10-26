//
//  CenterOptions.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation

/// What the plan form needs to know about a centre.
struct CentreOption: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
}

/// Where centres come from. Today: a fixed list. Monday: Firestore (same protocol).
protocol CentresProviding {
    func fetchCentres() async throws -> [CentreOption]
}

/// TEMPORARY: real centres from centres.csv, so the plan form can be built before Firestore.
struct SampleCentresProvider: CentresProviding {
    func fetchCentres() async throws -> [CentreOption] {
        [
            CentreOption(id: "ekunu-19", name: "eKunu Collection Point - Modern",
                         address: "No: 528, Alfred House Avenue, R A De Mel Mawatha, Colombo 03"),
            CentreOption(id: "ekunu-17", name: "eKunu Collection Point - Nugegoda SC",
                         address: "No: 84, Stanley Thilakarathne Mawatha, Nugegoda"),
            CentreOption(id: "ekunu-14", name: "eKunu Collection Point - Kandy",
                         address: "No 178, D S Senanayake Street, Kandy"),
            CentreOption(id: "ekunu-15", name: "eKunu Collection Point - Galle",
                         address: "No 121A, Wackwella Road, Galle")
        ]
    }
}
