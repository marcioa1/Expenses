//
//  LoadingStateRecoveryTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct LoadingStateRecoveryTests {

    // MARK: - ExpensesListViewModel

    @Test func expensesListRecoversWhenConfigureIsRetried() async {
        let vm = ExpensesListViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1))
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }

    @Test func expensesListRefreshRetriesFailedCategories() async {
        let vm = ExpensesListViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1))
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        await vm.refreshExpenses()
        #expect(vm.loadingState == .success)
        #expect(!vm.categories.isEmpty)
    }

    @Test func expensesListRefreshFailsWhenExpensesFail() async {
        let vm = ExpensesListViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        // Fails both the initial load and the refresh.
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(failingFetches: 2))

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        await vm.refreshExpenses()
        #expect(vm.loadingState == .failed)
    }

    @Test func expensesListRefreshFailureKeepsDataAndShowsMessage() async {
        let vm = ExpensesListViewModel()
        let lunch = Expense(id: 1, categoryID: 1, value: 10)
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        let expenseRepository = MockExpenseDataProvider(expenses: [lunch])
        let expenseBasket = ExpenseBasket(expenseRepository: expenseRepository)

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
        #expect(vm.errorMessage == nil)

        // Pull-to-refresh fails: the list keeps what it had and tells the user it couldn't refresh.
        expenseRepository.fetchError = APIError.network
        await vm.refreshExpenses()
        #expect(vm.loadingState == .success)
        #expect(vm.expenses.map(\.id) == [1])
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Shared state across tabs

    @Test func recoveryOnOneTabClearsTheErrorOnAnother() async {
        // Two tabs sharing the same baskets, as in the app.
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(failingFetches: 1))
        let list = ExpensesListViewModel()
        let summary = SummaryViewModel()

        await list.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(list.loadingState == .failed)

        // The user opens the Summary tab, whose load retries and succeeds…
        await summary.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(summary.loadingState == .success)
        // …and the Expenses tab recovers too, without loading again itself.
        #expect(list.loadingState == .success)
    }

    @Test func failureIsTheSameOnEveryTab() async {
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        // Fails the list's load and the chart's retry.
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(failingFetches: 2))
        let list = ExpensesListViewModel()
        let chart = DailyChartViewModel()

        await list.configure(with: categoryBasket, expenseBasket: expenseBasket)
        await chart.configure(with: categoryBasket, expenseBasket: expenseBasket)

        #expect(list.loadingState == .failed)
        #expect(chart.loadingState == .failed)
    }

    // MARK: - MonthlyGridViewModel

    @Test func monthlyGridRecoversWhenConfigureIsRetried() async {
        let vm = MonthlyGridViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(failingFetches: 1))

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }

    @Test func monthlyGridFailsWhenCategoriesFail() async {
        let vm = MonthlyGridViewModel()
        #expect(vm.loadingState == .loading)

        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )

        #expect(vm.loadingState == .failed)
    }
}
