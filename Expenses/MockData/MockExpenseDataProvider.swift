//
//  MockExpenseDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

#if DEBUG
import Foundation

final class MockExpenseDataProvider: @MainActor ExpenseRepository {
    typealias Item = Expense

    private var expenses: [Expense]
    /// When set, every fetch throws this error (e.g. to preview the error screen). It can be changed
    /// between calls, e.g. set after a first successful load to simulate a failed refresh.
    var fetchError: Error?
    /// The next `failingFetches` fetches throw `MockRepositoryError.fetchFailed`, then fetches succeed
    /// again: a failed first load followed by a successful retry.
    var failingFetches: Int
    /// When set, `create`, `update` and `delete` throw this error (e.g. a network error on save).
    var writeError: Error?

    init(expenses: [Expense] = [], fetchError: Error? = nil, failingFetches: Int = 0, writeError: Error? = nil) {
        self.expenses = expenses
        self.fetchError = fetchError
        self.failingFetches = failingFetches
        self.writeError = writeError
    }

    func fetchAll() async throws -> [Expense] {
        try failFetchIfNeeded()
        return expenses.sorted { $0.datetime > $1.datetime }
    }

    /// Mimics the server by assigning the next available `id`.
    func create(_ draft: ExpenseDraft) async throws -> Expense {
        if let writeError { throw writeError }
        let nextID = (expenses.map(\.id).max() ?? 0) + 1
        let expense = Expense(
            id: nextID,
            categoryID: draft.categoryID,
            details: draft.details,
            value: draft.value,
            datetime: draft.datetime,
            latitude: draft.latitude,
            longitude: draft.longitude,
            locationName: draft.locationName,
            extraordinary: draft.extraordinary
        )
        expenses.append(expense)
        return expense
    }

    func update(_ expense: Expense) async throws -> Expense {
        if let writeError { throw writeError }
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
        return expense
    }

    func delete(_ expense: Expense) async throws {
        if let writeError { throw writeError }
        expenses.removeAll { $0.id == expense.id }
    }

    private func failFetchIfNeeded() throws {
        if failingFetches > 0 {
            failingFetches -= 1
            throw MockRepositoryError.fetchFailed
        }
        if let fetchError { throw fetchError }
    }
}
#endif
