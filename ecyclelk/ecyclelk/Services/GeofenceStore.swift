//
//  GeofenceStore.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-27.
//

import Foundation

@MainActor
protocol GeofenceStoring: AnyObject {
    
    var isEnabled: Bool{ get set }
    func lastAlert(for centreID: String) -> Date?
    func setLastAlert(_ date: Date, for centreID: String)
    
}


@MainActor
final class UserDefaultsGeofenceStore: GeofenceStoring {
    
    private let defaults: UserDefaults
    private let enabledKey = "geofence.enabled"
    private let alertsKey = "geofence.lastAlerts"
    
    init(defaults: UserDefaults = .standard){
        self.defaults = defaults }
    
    var isEnabled: Bool {
        get{ defaults.bool(forKey: enabledKey) }
        set { defaults.set(newValue, forKey: enabledKey) }
    }
    
    func lastAlert(for centreID: String) -> Date?{
        
        (defaults.dictionary(forKey: alertsKey) as? [String: Date])?[centreID]
    }
    
    func setLastAlert(_ date: Date, for centreID: String){
        
        var all = (defaults.dictionary(forKey: alertsKey) as? [String: Date]) ?? [:]
        all[centreID] = date
        defaults.set(all, forKey: alertsKey)

    }
    
}
