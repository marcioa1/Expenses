//
//  SessionStoreTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Foundation
import Testing
@testable import Expenses

// Serialized because every test reads and writes the same Keychain item.
@Suite(.serialized)
struct SessionStoreTests {
    // A dedicated key so tests never touch the app's real session.
    private let store = SessionStore(service: "SessionStoreTests", account: "testSession")

    init() {
        store.clear()
    }

    @Test func loadReturnsNilWhenNothingSaved() {
        #expect(store.load() == nil)
    }

    @Test func saveThenLoadReturnsSameSession() throws {
        let session = AuthSession(accessToken: "abc123", tokenType: "Bearer")

        try store.save(session)

        #expect(store.load() == session)
        store.clear()
    }

    @Test func saveOverwritesPreviousSession() throws {
        try store.save(AuthSession(accessToken: "old", tokenType: "Bearer"))
        let newSession = AuthSession(accessToken: "new", tokenType: "Bearer")

        try store.save(newSession)

        #expect(store.load() == newSession)
        store.clear()
    }

    @Test func clearRemovesSession() throws {
        try store.save(AuthSession(accessToken: "abc123", tokenType: "Bearer"))

        store.clear()

        #expect(store.load() == nil)
    }
}
