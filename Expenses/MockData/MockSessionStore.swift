//
//  MockSessionStore.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

#if DEBUG
import Foundation

/// In-memory `SessionStoring` for previews and tests, so they never touch the real Keychain.
final class MockSessionStore: SessionStoring {
    /// When set, `save` throws this error instead of storing the session.
    var saveError: Error?
    private(set) var session: AuthSession?

    init(session: AuthSession? = nil, saveError: Error? = nil) {
        self.session = session
        self.saveError = saveError
    }

    func save(_ session: AuthSession) throws {
        if let saveError { throw saveError }
        self.session = session
    }

    func load() -> AuthSession? {
        session
    }

    func clear() {
        session = nil
    }
}
#endif
