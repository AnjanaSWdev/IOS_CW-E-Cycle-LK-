//
//  AuthServiceProtocol.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-23.
//

import Foundation

/// Sign-in operations the app needs. The view model depends on this protocol,
/// so tests can use a fake instead of Firebase.
@MainActor
protocol AuthServiceProtocol {
    var currentUser: AuthUser? { get }
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(name: String, email: String, password: String) async throws -> AuthUser
    func signOut() throws
}

enum AuthFailure: LocalizedError {
    case invalidEmail, wrongCredentials, emailInUse, weakPassword
    case network, tooManyAttempts, unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "That email address doesn't look right."
        case .wrongCredentials: return "The email or password is incorrect."
        case .emailInUse: return "An account with this email already exists. Try signing in."
        case .weakPassword: return "Choose a password with at least 6 characters."
        case .network: return "No internet connection. Please try again."
        case .tooManyAttempts: return "Too many attempts. Please wait a moment and try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
