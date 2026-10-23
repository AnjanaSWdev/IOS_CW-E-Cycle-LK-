//
//  AuthViewModelTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Testing
@testable import ecyclelk   // use your module name as in your other test file

@MainActor
private final class FakeAuthService: AuthServiceProtocol {
    var currentUser: AuthUser?
    var failure: AuthFailure?

    func signIn(email: String, password: String) async throws -> AuthUser {
        if let failure { throw failure }
        let user = AuthUser(uid: "u1", email: email, name: "Tester")
        currentUser = user
        return user
    }

    func signUp(name: String, email: String, password: String) async throws -> AuthUser {
        if let failure { throw failure }
        let user = AuthUser(uid: "u2", email: email, name: name)
        currentUser = user
        return user
    }

    func signOut() throws { currentUser = nil }
}

@MainActor
struct AuthViewModelTests {
    private func makeViewModel() -> (AuthViewModel, FakeAuthService) {
        let service = FakeAuthService()
        return (AuthViewModel(service: service), service)
    }

    @Test func invalidEmailCannotSubmit() {
        let (viewModel, _) = makeViewModel()
        viewModel.email = "not-an-email"
        viewModel.password = "secret1"
        #expect(!viewModel.canSubmit)
    }

    @Test func shortPasswordCannotSubmit() {
        let (viewModel, _) = makeViewModel()
        viewModel.email = "a@b.com"
        viewModel.password = "123"
        #expect(!viewModel.canSubmit)
    }

    @Test func signUpNeedsAName() {
        let (viewModel, _) = makeViewModel()
        viewModel.mode = .signUp
        viewModel.email = "a@b.com"
        viewModel.password = "secret1"
        #expect(!viewModel.canSubmit)
        viewModel.name = "Amaya"
        #expect(viewModel.canSubmit)
    }

    @Test func successfulSignInMovesToSignedIn() async {
        let (viewModel, _) = makeViewModel()
        viewModel.email = "a@b.com"
        viewModel.password = "secret1"
        await viewModel.submit()
        #expect(viewModel.state == .signedIn(AuthUser(uid: "u1", email: "a@b.com", name: "Tester")))
        #expect(viewModel.password.isEmpty)
    }

    @Test func wrongPasswordShowsMessageAndStaysSignedOut() async {
        let (viewModel, service) = makeViewModel()
        service.failure = .wrongCredentials
        viewModel.email = "a@b.com"
        viewModel.password = "secret1"
        await viewModel.submit()
        #expect(viewModel.state == .signedOut)
        #expect(viewModel.errorMessage == AuthFailure.wrongCredentials.errorDescription)
    }

    @Test func signOutReturnsToSignedOut() async {
        let (viewModel, _) = makeViewModel()
        viewModel.email = "a@b.com"
        viewModel.password = "secret1"
        await viewModel.submit()
        viewModel.signOut()
        #expect(viewModel.state == .signedOut)
    }
}
