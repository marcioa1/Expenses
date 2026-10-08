//
//  MockAuthService.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

#if DEBUG
import Foundation

@MainActor
final class MockAuthService: AuthService {
    /// When set, `signIn` throws this error instead of succeeding.
    var error: AuthError?
    var delay: Duration

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0

    init(error: AuthError? = nil, delay: Duration = .zero) {
        self.error = error
        self.delay = delay
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        signInCallCount += 1
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        if let error { throw error }
        return AuthSession(
            accessToken: "mock-access-token",
            tokenType: "bearer"
        )
    }

    func signOut(_ session: AuthSession) async throws {
        signOutCallCount += 1
    }
}
#endif
