//
//  AuthService.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import Foundation

/// The result of a successful sign-in.
/// `nonisolated` opts this value type out of the target's default `MainActor` isolation.
nonisolated struct AuthSession: Codable, Equatable {
    let accessToken: String
    let tokenType: String
}

enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case network
    case server(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            String(localized: "Incorrect email or password.")
        case .network:
            String(localized: "Unable to connect. Check your internet connection and try again.")
        case .server:
            String(localized: "Something went wrong on our side. Please try again later.")
        case .invalidResponse:
            String(localized: "Received an unexpected response from the server.")
        }
    }
}

/// Abstraction over the sign-in backend so views and view models don't
/// depend on a concrete implementation (remote, mock, etc.).
@MainActor
protocol AuthService {
    func signIn(email: String, password: String) async throws -> AuthSession
    func signOut(_ session: AuthSession) async throws
}
