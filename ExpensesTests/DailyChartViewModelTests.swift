//
//  DailyChartViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct DailyChartViewModelTests {

    // MARK: - Daily totals

    @Test func dailyTotalsAreIdentifiedByDay() {
        let vm = DailyChartViewModel()
        let expenses = [Expense(id: 1, categoryID: 1, value: 10)]

        let totals = vm.expensesByDay(from: expenses)

        #expect(totals.map(\.id) == Array(1...vm.daysInMonth()))
        #expect(Set(totals.map(\.id)).count == totals.count)
    }

    @Test func dailyTotalIDsAreStableAcrossCalls() {
        let vm = DailyChartViewModel()
        let expenses = [Expense(id: 1, categoryID: 1, value: 10)]

        let first = vm.expensesByDay(from: expenses).map(\.id)
        let second = vm.expensesByDay(from: expenses).map(\.id)

        #expect(first == second)
    }

    // MARK: - Loading state

    @Test func startsLoading() {
        #expect(DailyChartViewModel().loadingState == .loading)
    }

    @Test func configureSucceedsWhenBothLoadsSucceed() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .success)
    }

    @Test func configureFailsWhenCategoriesFail() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureFailsWhenExpensesFail() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider(fetchError: APIError.network))
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureRecoversOnRetry() async {
        let vm = DailyChartViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1))
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        // E.g. the user comes back to the tab, which runs `configure` again.
        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }
}
