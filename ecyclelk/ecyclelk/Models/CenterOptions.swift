//
//  CenterOptions.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation

// What the plan form needs to know about a centre.
struct CentreOption: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
}

// Where centres come from.
protocol CentresProviding {
    func fetchCentres() async throws -> [CentreOption]
}


