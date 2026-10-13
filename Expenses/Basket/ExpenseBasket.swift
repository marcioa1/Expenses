//
//  ExpenseBasket.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/09/26.
//

import Foundation
import Observation

/// App-wide store of expenses, shared by every screen through the SwiftUI environment.
///
/// Expenses are fetched once (`loadIfNeeded()`) and kept in memory, newest first; writes go
/// through the repository and update `expenses` in place so every tab sees the change.
@MainActor
@Observable
final class ExpenseBasket {
    private let expenseRepository: (any ExpenseRepository)?
    private(set) var expenses: [Expense]
    private(set) var hasLoaded = false
    /// In-flight fetch, so tabs appearing at the same time share a single request.
    @ObservationIgnored private var loadTask: Task<Void, Error>?

    /// - Parameter expenses: Initial expenses; handy for previews and tests that don't need a repository.
    init(expenseRepository: (any ExpenseRepository)? = nil, expenses: [Expense] = []) {
        self.expenseRepository = expenseRepository
        self.expenses = expenses
        sortExpenses()
    }

    // MARK: - Loading

    /// Fetches expenses only if they haven't been loaded yet.
    func loadIfNeeded() async throws {
        guard !hasLoaded else { return }
        if let loadTask {
            return try await loadTask.value
        }
        let task = Task { try await getAllExpenses() }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    /// Always fetches expenses from the repository (e.g. pull-to-refresh).
    func getAllExpenses() async throws {
        guard let expenseRepository else { return }
        expenses = try await expenseRepository.fetchAll()
        sortExpenses()
        hasLoaded = true
    }

    /// Drops all loaded expenses (e.g. on logout) so the next user starts with a fresh fetch.
    func reset() {
        loadTask?.cancel()
        loadTask = nil
        expenses = []
        hasLoaded = false
    }

    // MARK: - Writes

    func create(_ draft: ExpenseDraft) async throws {
        guard let expenseRepository else { return }
        let created = try await expenseRepository.create(draft)
        expenses.append(created)
        sortExpenses()
    }

    func update(_ expense: Expense) async throws {
        guard let expenseRepository else { return }
        let updated = try await expenseRepository.update(expense)
        if let index = expenses.firstIndex(where: { $0.id == updated.id }) {
            expenses[index] = updated
        }
        sortExpenses()
    }

    func delete(_ expense: Expense) async throws {
        guard let expenseRepository else { return }
        try await expenseRepository.delete(expense)
        expenses.removeAll { $0.id == expense.id }
    }

    // MARK: - Lookups

    func expense(withID id: Int) -> Expense? {
        expenses.first { $0.id == id }
    }

    /// Loaded expenses whose `datetime` falls within `startDate...endDate`, newest first.
    func expenses(from startDate: Date, to endDate: Date) -> [Expense] {
        expenses.filter { $0.datetime >= startDate && $0.datetime <= endDate }
    }

    /// Category of the most recent expense recorded at `locationName`, used to pre-select
    /// a category in the expense form. `expenses` is sorted newest first, so the first match wins.
    func latestCategoryID(forLocationName locationName: String) -> Int? {
        expenses.first { $0.locationName == locationName }?.categoryID
    }

    private func sortExpenses() {
        expenses.sort { $0.datetime > $1.datetime }
    }
}
