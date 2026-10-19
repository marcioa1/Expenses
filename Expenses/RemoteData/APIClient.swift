//
//  APIClient.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {
    /// ISO 8601 dates with or without fractional seconds and timezone.
    ///
    /// The backend sends some timestamps without an offset (e.g. `"2026-10-10T20:26:33"`, an Ecto
    /// `naive_datetime`), which the built-in `.iso8601` strategy rejects; those are read as UTC.
    static var flexibleISO8601: Self {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Date.parseISO8601(string) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Unsupported date format: \(string)"
                )
            }
            return date
        }
    }
}

extension Date {
    /// Parses an ISO 8601 date; a value without a timezone is treated as UTC.
    nonisolated static func parseISO8601(_ string: String) -> Date? {
        let style = Date.ISO8601FormatStyle()
        return (try? style.parse(string)) ?? (try? style.parse(string + "Z"))
    }
}

extension Notification.Name {
    /// Posted by `APIClient` when an authenticated request gets `401 Unauthorized`.
    static let sessionExpired = Notification.Name("APIClient.sessionExpired")
}

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

/// The single HTTP JSON client of the app, shared by the auth service and the remote repositories.
///
/// - Resolves paths against `baseURL`.
/// - Attaches `Authorization: <tokenType> <accessToken>` from the stored session, if any.
/// - Encodes request bodies and decodes responses as JSON.
/// - Maps transport / HTTP failures to `APIError`.
///
/// It's built once in `ExpensesApp` with the app's `SessionStore`, so the base URL, the token
/// and the header format are defined in one place.
///
/// Usage:
/// ```swift
/// let client = APIClient(baseURL: AppConfiguration.apiBaseURL, sessionStore: sessionStore)
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
    private let sessionStore: any SessionStoring
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        sessionStore: any SessionStoring
    ) {
        self.baseURL = baseURL
        self.session = session
        self.sessionStore = sessionStore

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleISO8601
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

    /// Sends a body-less `POST` authorized by `authSession` instead of the stored session, ignoring
    /// the response body. Used to sign out: by then the app has already cleared the stored session.
    ///
    /// A `401` here doesn't post `.sessionExpired`, since the user is already logging out.
    func post(_ path: String, authorizedBy authSession: AuthSession) async throws {
        let request = try makeRequest(.post, path, query: [], body: Optional<Data>.none, authSession: authSession)
        _ = try await send(request, reportsSessionExpiry: false)
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

    /// - Parameter authSession: Token to send instead of the stored session (see `post(_:authorizedBy:)`).
    private func makeRequest<Body: Encodable>(
        _ method: Method,
        _ path: String,
        query: [URLQueryItem],
        body: Body?,
        authSession: AuthSession? = nil
    ) throws -> URLRequest {
        var url = baseURL.appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let authSession = authSession ?? sessionStore.load() {
            request.setValue(
                "\(authSession.tokenType.capitalized) \(authSession.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        #if DEBUG
        logRequest(request)
        #endif
        return request
    }

    #if DEBUG
    /// Prints the outgoing request (method, URL and JSON body) to the console in debug builds.
    /// The `Authorization` header is intentionally left out so the access token never hits the logs.
    private func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        let body = request.httpBody.map { String(decoding: $0, as: UTF8.self) } ?? "<no body>"
        print("[APIClient] \(method) \(url)\n[APIClient] Body: \(body)")
    }

    /// Prints the status code and raw response body in debug builds, to check the backend's JSON
    /// against the app's models (wrapper keys, field names, date and decimal formats).
    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        let url = response.url?.absoluteString ?? "?"
        let body = data.isEmpty ? "<no body>" : String(decoding: data, as: UTF8.self)
        print("[APIClient] ← \(response.statusCode) \(url)\n[APIClient] Response: \(body)")
    }
    #endif

    /// Performs the request and maps transport / HTTP failures to `APIError`.
    /// - Parameter reportsSessionExpiry: Whether a `401` on an authorized request posts `.sessionExpired`.
    private func send(_ request: URLRequest, reportsSessionExpiry: Bool = true) async throws -> Data {
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

        #if DEBUG
        logResponse(httpResponse, data: data)
        #endif

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            // Only a request that carried a token means the session expired;
            // the app listens for this and returns to the login screen.
            if reportsSessionExpiry, request.value(forHTTPHeaderField: "Authorization") != nil {
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            }
            throw APIError.unauthorized
        case 403:
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
