//
//  ExpenseBasketTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

import Testing
import Foundation
@testable import Expenses

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

    // MARK: - loadState

    @Test func loadStateStartsLoadingAndSucceeds() async throws {
        let basket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        #expect(basket.loadState == .loading)

        try await basket.loadIfNeeded()
        #expect(basket.loadState == .success)
    }

    @Test func failedFirstLoadIsFailedAndRetryRecovers() async throws {
        let repository = MockExpenseDataProvider(expenses: [Expense(id: 1, categoryID: 1, value: 10)])
        repository.fetchError = APIError.network
        let basket = ExpenseBasket(expenseRepository: repository)

        await #expect(throws: APIError.network) { try await basket.loadIfNeeded() }
        #expect(basket.loadState == .failed)

        // E.g. the user comes back to a tab once the connection is back.
        repository.fetchError = nil
        try await basket.loadIfNeeded()
        #expect(basket.loadState == .success)
        #expect(basket.expenses.map(\.id) == [1])
    }

    @Test func failedRefreshKeepsDataAndSuccess() async throws {
        let repository = MockExpenseDataProvider(expenses: [Expense(id: 1, categoryID: 1, value: 10)])
        let basket = ExpenseBasket(expenseRepository: repository)
        try await basket.loadIfNeeded()

        repository.fetchError = APIError.network
        // The caller (pull-to-refresh) still gets the error, to tell the user…
        await #expect(throws: APIError.network) { try await basket.getAllExpenses() }
        // …but every screen keeps showing the expenses it already had.
        #expect(basket.loadState == .success)
        #expect(basket.expenses.map(\.id) == [1])
    }

    @Test func resetGoesBackToLoading() async throws {
        let basket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        try await basket.loadIfNeeded()

        basket.reset()

        #expect(basket.loadState == .loading)
    }

    @Test func basketWithoutRepositoryIsLoadedAfterLoad() async throws {
        // Previews and tests that only pass initial data.
        let basket = ExpenseBasket(expenses: [Expense(id: 1, categoryID: 1, value: 10)])

        try await basket.loadIfNeeded()

        #expect(basket.loadState == .success)
        #expect(basket.expenses.count == 1)
    }

    // MARK: - LoadingState.combined

    @Test func combinedLoadingState() {
        #expect(LoadingState.combined(.success, .success) == .success)
        #expect(LoadingState.combined(.success, .loading) == .loading)
        #expect(LoadingState.combined(.loading, .failed) == .failed)
        #expect(LoadingState.combined(.failed, .success) == .failed)
    }
}
