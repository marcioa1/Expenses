//
//  ExpenseRepository.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

import Foundation

/// Read/write access to expenses (remote API, mock, etc.).
@MainActor
protocol ExpenseRepository: DataProvider where Item == Expense {
    /// Creates an expense; the returned value carries the server-assigned `id`.
    func create(_ draft: ExpenseDraft) async throws -> Expense
    func update(_ expense: Expense) async throws -> Expense
    func delete(_ expense: Expense) async throws
}
