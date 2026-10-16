//
//  SessionStoring.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Foundation

/// Persists the signed-in `AuthSession` (Keychain, in-memory mock, etc.).
protocol SessionStoring {
    func save(_ session: AuthSession) throws
    func load() -> AuthSession?
    func clear()
}
