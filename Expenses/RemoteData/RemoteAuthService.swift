//
//  RemoteAuthService.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import Foundation

/// `AuthService` backed by the HTTP JSON API, sending through the app's shared `APIClient`.
///
/// Contract:
/// - `POST api/auth/login`  body `{ "email", "password" }`
///   → `200 { "access_token", "token_type" }`
///   → `401` / `403` on invalid credentials
/// - `POST api/auth/logout` with `Authorization: <tokenType> <accessToken>` (e.g. `Bearer …`)
final class RemoteAuthService: AuthService {
    private enum Endpoint {
        static let login = "api/auth/login"
        static let logout = "api/auth/logout"
    }

    private struct SignInRequest: Encodable {
        let email: String
        let password: String
    }

    private nonisolated struct SignInResponse: Decodable {
        let accessToken: String
        let tokenType: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
        }
    }

    private let client: APIClient

    /// - Parameter client: The app's shared `APIClient`, built once in `ExpensesApp`.
    init(client: APIClient) {
        self.client = client
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        do {
            let response: SignInResponse = try await client.post(
                Endpoint.login,
                body: SignInRequest(email: email, password: password)
            )
            return AuthSession(accessToken: response.accessToken, tokenType: response.tokenType)
        } catch let error as APIError {
            throw AuthError(error)
        }
    }

    func signOut(_ authSession: AuthSession) async throws {
        do {
            // The app clears the stored session before signing out, so the token is passed explicitly.
            try await client.post(Endpoint.logout, authorizedBy: authSession)
        } catch let error as APIError {
            throw AuthError(error)
        }
    }
}

private extension AuthError {
    /// Maps the shared client's errors to the messages the login screen shows.
    init(_ error: APIError) {
        switch error {
        case .unauthorized:
            // `APIClient` reports both 401 and 403 as `.unauthorized`.
            self = .invalidCredentials
        case .network:
            self = .network
        case .server(let statusCode):
            self = .server(statusCode: statusCode)
        case .notFound, .invalidResponse, .decoding:
            self = .invalidResponse
        }
    }
}
