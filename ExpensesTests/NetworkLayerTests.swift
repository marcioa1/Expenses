//
//  NetworkLayerTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 19/10/26.
//

import Testing
import Foundation
@testable import Expenses

/// Answers every request of a `URLSession` with `handler`, so the network layer runs without a server.
private final class StubURLProtocol: URLProtocol {
    /// Returns the response for a request, or throws to simulate a transport failure.
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Int, Data))?
    /// The last request received, to check its URL and headers.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        Self.lastRequest = request
        do {
            guard let handler = Self.handler, let url = request.url else { throw URLError(.badServerResponse) }
            let (statusCode, data) = try handler(request)
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

/// Counts `.sessionExpired` notifications while a test runs.
private final class SessionExpiredCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0
    private var observer: NSObjectProtocol?

    var count: Int { lock.withLock { _count } }

    init() {
        observer = NotificationCenter.default.addObserver(forName: .sessionExpired, object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }
            lock.withLock { self._count += 1 }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }
}

/// `APIClient` and `RemoteAuthService` against a stubbed network.
/// Serialized because the stub's handler is shared.
@Suite(.serialized)
@MainActor
struct NetworkLayerTests {
    private let baseURL = URL(string: "https://api.example.com")!
    private let storedSession = AuthSession(accessToken: "stored-token", tokenType: "bearer")

    private func makeClient(sessionStore: MockSessionStore? = nil) -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(
            baseURL: baseURL,
            session: URLSession(configuration: configuration),
            sessionStore: sessionStore ?? MockSessionStore()
        )
    }

    private func stub(status: Int, json: String = "{}") {
        StubURLProtocol.lastRequest = nil
        StubURLProtocol.handler = { _ in (status, Data(json.utf8)) }
    }

    // MARK: - APIClient

    @Test func storedSessionIsSentAsAuthorizationHeader() async throws {
        stub(status: 200, json: #"{"categories": []}"#)
        let repository = CategoryRemoteDataProvider(client: makeClient(sessionStore: MockSessionStore(session: storedSession)))

        _ = try await repository.fetchAll()

        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.url?.absoluteString == "https://api.example.com/api/categories")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer stored-token")
    }

    @Test func unauthorizedWithStoredTokenReportsSessionExpired() async {
        stub(status: 401)
        let counter = SessionExpiredCounter()
        let repository = CategoryRemoteDataProvider(client: makeClient(sessionStore: MockSessionStore(session: storedSession)))

        await #expect(throws: APIError.unauthorized) { try await repository.fetchAll() }
        #expect(counter.count == 1)
    }

    // MARK: - RemoteAuthService.signIn

    @Test func signInDecodesTheSession() async throws {
        stub(status: 200, json: #"{"access_token": "new-token", "token_type": "bearer"}"#)
        let service = RemoteAuthService(client: makeClient())

        let session = try await service.signIn(email: "user@example.com", password: "secret")

        #expect(session == AuthSession(accessToken: "new-token", tokenType: "bearer"))
        #expect(StubURLProtocol.lastRequest?.url?.path() == "/api/auth/login")
        #expect(StubURLProtocol.lastRequest?.httpMethod == "POST")
    }

    @Test func signInWithWrongCredentialsIsInvalidCredentials() async {
        stub(status: 401)
        let counter = SessionExpiredCounter()
        let service = RemoteAuthService(client: makeClient())

        await #expect(throws: AuthError.invalidCredentials) {
            try await service.signIn(email: "user@example.com", password: "wrong")
        }
        // No token was sent, so a 401 here is a wrong password, not an expired session.
        #expect(counter.count == 0)
    }

    @Test func signInForbiddenIsInvalidCredentials() async {
        stub(status: 403)
        let service = RemoteAuthService(client: makeClient())

        await #expect(throws: AuthError.invalidCredentials) {
            try await service.signIn(email: "user@example.com", password: "wrong")
        }
    }

    @Test func signInServerErrorKeepsStatusCode() async {
        stub(status: 500)
        let service = RemoteAuthService(client: makeClient())

        await #expect(throws: AuthError.server(statusCode: 500)) {
            try await service.signIn(email: "user@example.com", password: "secret")
        }
    }

    @Test func signInWithoutConnectionIsNetworkError() async {
        StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let service = RemoteAuthService(client: makeClient())

        await #expect(throws: AuthError.network) {
            try await service.signIn(email: "user@example.com", password: "secret")
        }
    }

    @Test func signInWithUnexpectedBodyIsInvalidResponse() async {
        stub(status: 200, json: #"{"unexpected": true}"#)
        let service = RemoteAuthService(client: makeClient())

        await #expect(throws: AuthError.invalidResponse) {
            try await service.signIn(email: "user@example.com", password: "secret")
        }
    }

    // MARK: - RemoteAuthService.signOut

    @Test func signOutSendsTheGivenTokenEvenWithEmptyStore() async throws {
        // The app clears the stored session before signing out.
        stub(status: 204, json: "")
        let service = RemoteAuthService(client: makeClient(sessionStore: MockSessionStore()))
        let session = AuthSession(accessToken: "old-token", tokenType: "bearer")

        try await service.signOut(session)

        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.url?.path() == "/api/auth/logout")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer old-token")
    }

    @Test func signOutRejectedDoesNotReportSessionExpired() async {
        stub(status: 401)
        let counter = SessionExpiredCounter()
        let service = RemoteAuthService(client: makeClient())

        await #expect(throws: AuthError.invalidCredentials) {
            try await service.signOut(AuthSession(accessToken: "old-token", tokenType: "bearer"))
        }
        // The user is already logging out; posting it would run the logout cleanup a second time.
        #expect(counter.count == 0)
    }
}
