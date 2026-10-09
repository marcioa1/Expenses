//
//  LoginViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import Testing
@testable import Expenses

@MainActor
struct LoginViewModelTests {

    // MARK: - Validation

    @Test func cannotSubmitWithEmptyFields() {
        let vm = LoginViewModel(authService: MockAuthService())
        #expect(vm.canSubmit == false)
        #expect(vm.emailError == nil)
    }

    @Test func invalidEmailShowsError() {
        let vm = LoginViewModel(authService: MockAuthService())
        vm.email = "not-an-email"
        vm.password = "secret"
        #expect(vm.emailError != nil)
        #expect(vm.canSubmit == false)
    }

    @Test func validCredentialsCanSubmit() {
        let vm = LoginViewModel(authService: MockAuthService())
        vm.email = " user@example.com "
        vm.password = "secret"
        #expect(vm.emailError == nil)
        #expect(vm.canSubmit)
    }

    // MARK: - login

    @Test func successfulLoginReturnsSession() async {
        let service = MockAuthService()
        let vm = LoginViewModel(authService: service)
        vm.email = " user@example.com "
        vm.password = "secret"

        let session = await vm.login()

        #expect(session?.accessToken == "mock-access-token")
        #expect(service.signInCallCount == 1)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test func failedLoginSetsErrorMessage() async {
        let vm = LoginViewModel(authService: MockAuthService(error: .invalidCredentials))
        vm.email = "user@example.com"
        vm.password = "wrong"

        let session = await vm.login()

        #expect(session == nil)
        #expect(vm.errorMessage == AuthError.invalidCredentials.errorDescription)
        #expect(vm.isLoading == false)
    }

    @Test func loginDoesNotCallServiceWhenInvalid() async {
        let service = MockAuthService()
        let vm = LoginViewModel(authService: service)
        vm.email = "bad"

        let session = await vm.login()

        #expect(session == nil)
        #expect(service.signInCallCount == 0)
    }
}
