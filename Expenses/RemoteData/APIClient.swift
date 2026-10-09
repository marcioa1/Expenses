//
//  APIClient.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Foundation

enum APIError: LocalizedError, Equatable {
    case unauthorized
    case notFound
    case network
    case server(statusCode: Int)
    case invalidResponse
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            String(localized: "Your session has expired. Please sign in again.")
        case .notFound:
            String(localized: "The requested item could not be found.")
        case .network:
            String(localized: "Unable to connect. Check your internet connection and try again.")
        case .server:
            String(localized: "Something went wrong on our side. Please try again later.")
        case .invalidResponse, .decoding:
            String(localized: "Received an unexpected response from the server.")
        }
    }
}

/// Generic HTTP JSON client used by the remote data providers.
///
/// - Resolves paths against `baseURL` (defaults to `AppConfiguration.apiBaseURL`).
/// - Attaches `Authorization: <tokenType> <accessToken>` from the Keychain session, if any.
/// - Encodes request bodies and decodes responses as JSON.
/// - Maps transport / HTTP failures to `APIError`.
///
/// Usage:
/// ```swift
/// let client = APIClient()
/// let categories: [CategoryDTO] = try await client.get("api/categories")
/// let created: CategoryDTO = try await client.post("api/categories", body: newCategory)
/// try await client.delete("api/categories/\(id)")
/// ```
struct APIClient {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    private let baseURL: URL
    private let session: URLSession
    private let sessionStore: SessionStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL = AppConfiguration.apiBaseURL,
        session: URLSession = .shared,
        sessionStore: SessionStore = SessionStore()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.sessionStore = sessionStore

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Convenience

    func get<Response: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Response {
        try await request(.get, path, query: query)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try await request(.post, path, body: body)
    }

    func put<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try await request(.put, path, body: body)
    }

    func patch<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try await request(.patch, path, body: body)
    }

    func delete(_ path: String) async throws {
        _ = try await send(makeRequest(.delete, path, query: [], body: Optional<Data>.none))
    }

    // MARK: - Core

    /// Sends a request without a body and decodes the JSON response.
    func request<Response: Decodable>(
        _ method: Method,
        _ path: String,
        query: [URLQueryItem] = []
    ) async throws -> Response {
        let data = try await send(makeRequest(method, path, query: query, body: Optional<Data>.none))
        return try decode(data)
    }

    /// Sends a request with a JSON body and decodes the JSON response.
    func request<Body: Encodable, Response: Decodable>(
        _ method: Method,
        _ path: String,
        query: [URLQueryItem] = [],
        body: Body
    ) async throws -> Response {
        let data = try await send(makeRequest(method, path, query: query, body: body))
        return try decode(data)
    }

    // MARK: - Private

    private func makeRequest<Body: Encodable>(
        _ method: Method,
        _ path: String,
        query: [URLQueryItem],
        body: Body?
    ) throws -> URLRequest {
        var url = baseURL.appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let authSession = sessionStore.load() {
            request.setValue(
                "\(authSession.tokenType.capitalized) \(authSession.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        return request
    }

    /// Performs the request and maps transport / HTTP failures to `APIError`.
    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.network
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.server(statusCode: httpResponse.statusCode)
        }
    }

    private func decode<Response: Decodable>(_ data: Data) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
