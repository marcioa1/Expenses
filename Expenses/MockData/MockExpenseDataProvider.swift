//
//  MockExpenseDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

#if DEBUG
import Foundation

@MainActor
final class MockExpenseDataProvider: @MainActor ExpenseRepository {
    typealias Item = Expense

    private var expenses: [Expense]
    /// When set, `fetchAll` throws this error instead of returning expenses (e.g. to preview the error screen).
    var fetchError: Error?

    init(expenses: [Expense] = [], fetchError: Error? = nil) {
        self.expenses = expenses
        self.fetchError = fetchError
    }

    func fetchAll() async throws -> [Expense] {
        if let fetchError { throw fetchError }
        return expenses.sorted { $0.datetime > $1.datetime }
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [Expense] {
        expenses
            .filter { $0.datetime >= startDate && $0.datetime <= endDate }
            .sorted { $0.datetime > $1.datetime }
    }

    /// Mimics the server by assigning the next available `id`.
    func create(_ draft: ExpenseDraft) async throws -> Expense {
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
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
        return expense
    }

    func delete(_ expense: Expense) async throws {
        expenses.removeAll { $0.id == expense.id }
    }
}
#endif
