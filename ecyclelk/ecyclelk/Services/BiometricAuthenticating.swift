//
//  BiometricAuthenticating.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import LocalAuthentication

@MainActor
protocol BiometricAuthenticating {
    
    var isAvailable: Bool { get}
    func authenticate(reason: String) async -> Bool
    
}


@MainActor
final class LocalAuthBiometrics: BiometricAuthenticating {
    
    var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do{
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
          return false
        }
        
    }
}
