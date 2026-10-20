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

    /// A view model on the current month, backed by in-memory baskets that load right away.
    private func makeViewModel(expenses: [Expense]) async -> DailyChartViewModel {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categories: [Category(id: 1, name: "Food")]),
            expenseBasket: ExpenseBasket(expenses: expenses)
        )
        return vm
    }

    @Test func dailyTotalsAreIdentifiedByDay() async {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 1, value: 10)])

        let totals = vm.dailyTotals

        #expect(totals.map(\.id) == Array(1...vm.daysInMonth()))
        #expect(Set(totals.map(\.id)).count == totals.count)
    }

    @Test func dailyTotalIDsAreStableAcrossCalls() async {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 1, value: 10)])

        #expect(vm.dailyTotals.map(\.id) == vm.dailyTotals.map(\.id))
    }

    @Test func dailyTotalsSumTheDayAndApplyTheFilter() async {
        let vm = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: 1, value: 10),
            Expense(id: 2, categoryID: 1, value: 15, extraordinary: true),
        ])
        let today = Calendar.current.component(.day, from: .now)

        #expect(vm.dailyTotals.first { $0.day == today }?.total == 25)

        vm.filter.extra = .regular
        #expect(vm.dailyTotals.first { $0.day == today }?.total == 10)
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
