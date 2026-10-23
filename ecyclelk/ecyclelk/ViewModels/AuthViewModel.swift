//
//  AuthViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    
    enum Mode: String, CaseIterable, Identifiable{
        
        case signIn = "Sign in"
        case signUp = "Create account"
        var id: String { rawValue }
    }
    
    enum State: Equatable{
        case signedOut
        case signedIn(AuthUser)
    }
    
    private(set) var state: State
    private(set) var isWorking = false
    var errorMessage: String?
    var name = ""
    var email = ""
    var password = ""
    var mode: Mode = .signIn{
        
        didSet {errorMessage = nil}
    }
    
    private let service: AuthServiceProtocol
    
    
    init(service: AuthServiceProtocol){
        self.service = service
        
        if let user = service.currentUser{
            state = .signedIn(user)
        }else{
            state = .signedOut
        }
    }
    
    // MARK: Validation
    
    static func isValidEmail(_ email: String) -> Bool {
            let trimmed = email.trimmingCharacters(in: .whitespaces)
            let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
            guard parts.count == 2, !parts[0].isEmpty else { return false }
            let domain = parts[1]
            return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
        }

        var canSubmit: Bool {
            guard Self.isValidEmail(email), password.count >= 6 else { return false }
            if mode == .signUp {
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        }
    
    // MARK: Actions
    
    func submit() async{
        
        guard canSubmit, !isWorking else {return}
        isWorking = true
        errorMessage = nil
        defer {isWorking = false}
        
        let cleanEmail = email.trimmingCharacters(in: .whitespaces)
        do{
            let user: AuthUser
            if mode == .signIn{
                user = try await service.signIn(email: cleanEmail, password: password)
            }else{
                let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                user = try await service.signUp(name: cleanName, email: cleanEmail, password: password)
            }
            password = ""
            state = .signedIn(user)
            
        } catch{
            errorMessage = error.localizedDescription
        }
            
        
    }
    
    func signOut(){
        
        do{
            try service.signOut()
            name = ""
            email = ""
            password = ""
            state = .signedOut
        } catch{
            
            errorMessage = error.localizedDescription
        }
    }
    
}
