//
//  ImpactViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@MainActor
@Observable
final class ImpactViewModel {
    private(set) var stats = RecyclingStats.empty
    private(set) var upcomingPlans: [PlanRecord] = []
    var errorMessage: String?
    
    private let items: AllItemsProviding
    private let plans: PlansServiceProtocol
    private let ownerUID: String
    private let now: () -> Date
    
    init(items: AllItemsProviding,
         plans: PlansServiceProtocol,
         ownerUID: String = "local",
         now: @escaping () -> Date = { Date() }){
        self.items = items
        self.plans = plans
        self.ownerUID = ownerUID
        self.now = now
    }
    
    var nextPlan: PlanRecord? { upcomingPlans.first }
    
    func load() {
        do{
            stats = RecyclingStats.make(from: try items.fetchAllItems(ownerUID: ownerUID), now: now())
            upcomingPlans = try plans.fetchPlans(ownerUID: ownerUID)
                .filter { $0.status == .upcoming }
                .sorted{ $0.start < $1.start}
        }catch{
            errorMessage = error.localizedDescription
        }
    }
}
