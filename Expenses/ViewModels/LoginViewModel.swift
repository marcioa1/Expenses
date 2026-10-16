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
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService: any AuthService
    private let sessionStore: any SessionStoring

    init(authService: any AuthService, sessionStore: any SessionStoring = SessionStore()) {
        self.authService = authService
        self.sessionStore = sessionStore
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

    /// Signs in and persists the session.
    /// - Returns: The session when authentication **and** saving succeed, `nil` otherwise
    ///   (`errorMessage` explains why).
    @MainActor
    func login() async -> AuthSession? {
        guard canSubmit else { return nil }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let session: AuthSession
        do {
            session = try await authService.signIn(email: trimmedEmail, password: password)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }

        do {
            // Every API request reads the token from the store, so without a saved session the
            // app would get in but all requests would fail. Stay on the login screen instead.
            try sessionStore.save(session)
            return session
        } catch {
            errorMessage = error.localizedDescription
            // Best-effort: revoke the token we couldn't keep.
            try? await authService.signOut(session)
            return nil
        }
    }
}
