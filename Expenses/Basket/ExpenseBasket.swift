//
//  ExpenseBucket.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/09/26.
//

import Foundation

final class ExpenseBasket {
    private var expenseRepository: (any DataProvider)?
    var expenses: [Expense] = []

    init(expenseRepository: (any DataProvider)? = nil, expenses: [Expense] = []) {
        self.expenseRepository = expenseRepository
        self.expenses = expenses
    }

    func getAllExpenses() async throws {
        guard let expenseRepository else { return }
        self.expenses = try await expenseRepository.fetchAll() as! [Expense]
    }
}
