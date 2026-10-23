//
//  FirebaseAuthService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import FirebaseAuth
import Foundation

@MainActor
final class FirebaseAuthService: AuthServiceProtocol {
    var currentUser: AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthUser(uid: user.uid, email: user.email ?? "", name: user.displayName ?? "")
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid,
                            email: result.user.email ?? email,
                            name: result.user.displayName ?? "")
        } catch {
            throw Self.map(error)
        }
    }

    func signUp(name: String, email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
            return AuthUser(uid: result.user.uid, email: email, name: name)
        } catch {
            throw Self.map(error)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthFailure.unknown
        }
    }

    /// Turns Firebase error codes into our own readable errors.
    private static func map(_ error: Error) -> AuthFailure {
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else { return .unknown }
        switch code {
        case .invalidEmail: return .invalidEmail
        case .wrongPassword, .invalidCredential, .userNotFound: return .wrongCredentials
        case .emailAlreadyInUse: return .emailInUse
        case .weakPassword: return .weakPassword
        case .networkError: return .network
        case .tooManyRequests: return .tooManyAttempts
        default: return .unknown
        }
    }
}
