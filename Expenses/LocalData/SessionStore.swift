//
//  SessionStore.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Foundation
import Security

enum SessionStoreError: Error, Equatable {
    case unexpectedStatus(OSStatus)
}

/// Persists the signed-in `AuthSession` in the Keychain so the user stays
/// logged in across launches.
struct SessionStore {
    /// `service` + `account` together form the unique key of the Keychain item.
    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "Expenses",
        account: String = "authSession"
    ) {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(session)
        // Remove any previous item so SecItemAdd can't fail with errSecDuplicateItem.
        SecItemDelete(baseQuery as CFDictionary)

        var query = baseQuery
        query[kSecValueData as String] = data
        // Readable after the first unlock since boot; never migrated to another device.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SessionStoreError.unexpectedStatus(status)
        }
    }

    func load() -> AuthSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
