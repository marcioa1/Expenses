//
//  LoginViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import Testing
import Security
@testable import Expenses

@MainActor
struct LoginViewModelTests {

    // MARK: - Helpers

    /// Uses an in-memory session store so tests never touch the app's real Keychain item.
    private func makeViewModel(
        service: MockAuthService? = nil,
        sessionStore: MockSessionStore? = nil
    ) -> LoginViewModel {
        LoginViewModel(authService: service ?? MockAuthService(), sessionStore: sessionStore ?? MockSessionStore())
    }

    // MARK: - Validation

    @Test func cannotSubmitWithEmptyFields() {
        let vm = makeViewModel()
        #expect(vm.canSubmit == false)
        #expect(vm.emailError == nil)
    }

    @Test func invalidEmailShowsError() {
        let vm = makeViewModel()
        vm.email = "not-an-email"
        vm.password = "secret"
        #expect(vm.emailError != nil)
        #expect(vm.canSubmit == false)
    }

    @Test func validCredentialsCanSubmit() {
        let vm = makeViewModel()
        vm.email = " user@example.com "
        vm.password = "secret"
        #expect(vm.emailError == nil)
        #expect(vm.canSubmit)
    }

    // MARK: - login

    @Test func successfulLoginReturnsSession() async {
        let service = MockAuthService()
        let vm = makeViewModel(service: service)
        vm.email = " user@example.com "
        vm.password = "secret"

        let session = await vm.login()

        #expect(session?.accessToken == "mock-access-token")
        #expect(service.signInCallCount == 1)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test func successfulLoginSavesSession() async {
        let store = MockSessionStore()
        let vm = makeViewModel(sessionStore: store)
        vm.email = "user@example.com"
        vm.password = "secret"

        let session = await vm.login()

        #expect(session != nil)
        #expect(store.load() == session)
    }

    @Test func failedLoginSetsErrorMessage() async {
        let vm = makeViewModel(service: MockAuthService(error: .invalidCredentials))
        vm.email = "user@example.com"
        vm.password = "wrong"

        let session = await vm.login()

        #expect(session == nil)
        #expect(vm.errorMessage == AuthError.invalidCredentials.errorDescription)
        #expect(vm.isLoading == false)
    }

    @Test func loginDoesNotCallServiceWhenInvalid() async {
        let service = MockAuthService()
        let vm = makeViewModel(service: service)
        vm.email = "bad"

        let session = await vm.login()

        #expect(session == nil)
        #expect(service.signInCallCount == 0)
    }

    // MARK: - Saving the session

    @Test func failedSaveKeepsUserOnLoginScreen() async {
        let saveError = SessionStoreError.unexpectedStatus(errSecInteractionNotAllowed)
        let store = MockSessionStore(saveError: saveError)
        let vm = makeViewModel(sessionStore: store)
        vm.email = "user@example.com"
        vm.password = "secret"

        let session = await vm.login()

        #expect(session == nil)
        #expect(store.load() == nil)
        #expect(vm.errorMessage == saveError.errorDescription)
        #expect(vm.isLoading == false)
    }

    @Test func failedSaveRevokesTheNewToken() async {
        let service = MockAuthService()
        let store = MockSessionStore(saveError: SessionStoreError.unexpectedStatus(errSecInteractionNotAllowed))
        let vm = makeViewModel(service: service, sessionStore: store)
        vm.email = "user@example.com"
        vm.password = "secret"

        _ = await vm.login()

        #expect(service.signOutCallCount == 1)
    }
}
