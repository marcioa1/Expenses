//
//  ExpenseBasketTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

import Testing
import Foundation
@testable import Expenses

@MainActor
struct ExpenseBasketTests {

    @Test func resetClearsExpensesAndAllowsReload() async throws {
        let lunch = Expense(id: 1, categoryID: 1, value: 10)
        let basket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: [lunch]))
        try await basket.loadIfNeeded()
        #expect(basket.hasLoaded)

        basket.reset()
        #expect(basket.expenses.isEmpty)
        #expect(!basket.hasLoaded)

        // The next user's first screen fetches again instead of reusing stale data.
        try await basket.loadIfNeeded()
        #expect(basket.expenses.map(\.id) == [1])
    }

    @Test func categoryBasketResetClearsCategories() async throws {
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        try await basket.loadIfNeeded()
        #expect(!basket.categories.isEmpty)

        basket.reset()
        #expect(basket.categories.isEmpty)
        #expect(!basket.hasLoaded)
    }
}
