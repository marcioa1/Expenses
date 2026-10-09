//
//  RemoteAuthService.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/10/26.
//

import Foundation

/// `AuthService` backed by an HTTP JSON API.
///
/// Assumed contract (adjust `Endpoint`, `SignInRequest` and `SignInResponse`
/// to match the real backend):
/// - `POST {baseURL}/auth/login`  body `{ "email", "password" }`
///   → `200 { "userId", "email", "accessToken", "refreshToken"?, "expiresAt"? }`
///   → `401` on invalid credentials
/// - `POST {baseURL}/auth/logout` with `Authorization: Bearer <accessToken>`
@MainActor
final class RemoteAuthService: AuthService {
    private enum Endpoint {
        static let login = "api/auth/login"
        static let logout = "api/auth/logout"
    }

    private struct SignInRequest: Encodable {
        let email: String
        let password: String
    }

    private struct SignInResponse: Decodable {
        let access_token: String
        let token_type: String
    }

    private let baseURL: URL
    private let session: URLSession

    private let encoder = JSONEncoder()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        var request = URLRequest(url: baseURL.appending(path: Endpoint.login))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(SignInRequest(email: email, password: password))

        let data = try await send(request)

        //TODO rewirte SignInResponse to get data from server at login
        guard let response = try? decoder.decode(SignInResponse.self, from: data) else {
            throw AuthError.invalidResponse
        }
        return AuthSession(
            accessToken: response.access_token,
            tokenType: response.token_type //,
        )
    }

    func signOut(_ authSession: AuthSession) async throws {
        var request = URLRequest(url: baseURL.appending(path: Endpoint.logout))
        request.httpMethod = "POST"
        request.setValue("Bearer \(authSession.accessToken)", forHTTPHeaderField: "Authorization")
        _ = try await send(request)
    }

    /// Sends the request and maps transport / HTTP failures to `AuthError`.
    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AuthError.network
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(statusCode: httpResponse.statusCode)
        }
    }
}
