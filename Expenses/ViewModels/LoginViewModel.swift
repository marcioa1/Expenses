//
//  LoginViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import Foundation
import Observation

@Observable
class LoginViewModel {
    var email: String = "marcio@ar1mobile.com.br"
    var password: String = "abcdefghijkl"
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService: any AuthService

    init(authService: any AuthService) {
        self.authService = authService
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespaces)
    }

    var isEmailValid: Bool {
        // Simple shape check: something@something.tld
        let pattern = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
        return trimmedEmail.wholeMatch(of: pattern) != nil
    }

    var emailError: String? {
        if trimmedEmail.isEmpty || isEmailValid { return nil }
        return String(localized: "Enter a valid email address.")
    }

    var canSubmit: Bool {
        isEmailValid && !password.isEmpty && !isLoading
    }

    /// Returns the session when authentication succeeds, `nil` otherwise.
    @MainActor
    func login() async -> AuthSession? {
        guard canSubmit else { return nil }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            return try await authService.signIn(email: trimmedEmail, password: password)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
