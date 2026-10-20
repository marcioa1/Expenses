//
//  ExpenseRemoteDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

import Foundation

/// `ExpenseRepository` backed by the HTTP JSON API.
///
/// Assumed contract (adjust `Endpoint` and `Expense.CodingKeys` to match the real backend):
/// - `GET    api/expenses`                   → `200 { "expenses": [Expense] }`
/// - `POST   api/expenses`                   body `{ "expense": ExpenseDraft }` (no `id`) → `200/201 { "expense": Expense }` with the new `id`
/// - `PUT    api/expenses/{id}`              body `{ "expense": Expense }` → `200 { "expense": Expense }`
/// - `DELETE api/expenses/{id}`              → `2xx`
struct ExpenseRemoteDataProvider: ExpenseRepository {
    private enum Endpoint {
        static let expenses = "api/expenses"

        static func expense(_ id: Int) -> String {
            "\(expenses)/\(id)"
        }
    }

    private let client: APIClient

    /// - Parameter client: The app's shared `APIClient`, built once in `ExpensesApp`.
    init(client: APIClient) {
        self.client = client
    }

    func fetchAll() async throws -> [Expense] {
        let response: ExpensesBody = try await client.get(Endpoint.expenses)
        // In server order; `ExpenseBasket` sorts them.
        return response.expenses
    }

    func create(_ draft: ExpenseDraft) async throws -> Expense {
        let response: ExpenseBody<Expense> = try await client.post(
            Endpoint.expenses,
            body: ExpenseBody(expense: draft)
        )
        return response.expense
    }

    func update(_ expense: Expense) async throws -> Expense {
        let response: ExpenseBody<Expense> = try await client.put(
            Endpoint.expense(expense.id),
            body: ExpenseBody(expense: expense)
        )
        return response.expense
    }

    func delete(_ expense: Expense) async throws {
        try await client.delete(Endpoint.expense(expense.id))
    }
}

/// Root `expense` key used by the backend in both directions: `{ "expense": { ... } }`.
nonisolated fileprivate struct ExpenseBody<Wrapped> {
    let expense: Wrapped
}

nonisolated extension ExpenseBody: Encodable where Wrapped: Encodable {}
nonisolated extension ExpenseBody: Decodable where Wrapped: Decodable {}
nonisolated extension ExpenseBody: Sendable where Wrapped: Sendable {}

/// Root `expenses` key used by the backend for the list: `{ "expenses": [ { ... } ] }`.
nonisolated fileprivate struct ExpensesBody: Decodable {
    let expenses: [Expense]
}
