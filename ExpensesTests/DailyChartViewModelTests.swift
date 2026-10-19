//
//  DailyChartViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

private struct LoadError: Error {}

/// Category repository whose first `failures` fetches fail and later ones succeed.
@MainActor
private final class FlakyCategoryRepository: @MainActor CategoryRepository {
    private var failuresRemaining: Int

    init(failures: Int) {
        self.failuresRemaining = failures
    }

    func fetchAll() async throws -> [Category] {
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw LoadError()
        }
        return [Category(id: 1, name: "Food")]
    }

    func create(_ draft: CategoryDraft) async throws -> Category { throw LoadError() }
    func update(_ category: Category) async throws -> Category { throw LoadError() }
    func delete(_ category: Category) async throws { throw LoadError() }
}

/// Expense repository whose fetch always fails.
@MainActor
private final class FailingExpenseRepository: @MainActor ExpenseRepository {
    func fetchAll() async throws -> [Expense] { throw LoadError() }
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Expense] { throw LoadError() }
    func create(_ draft: ExpenseDraft) async throws -> Expense { throw LoadError() }
    func update(_ expense: Expense) async throws -> Expense { throw LoadError() }
    func delete(_ expense: Expense) async throws { throw LoadError() }
}

@MainActor
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
            with: CategoryBasket(categoryRepository: FlakyCategoryRepository(failures: 1)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureFailsWhenExpensesFail() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: FailingExpenseRepository())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureRecoversOnRetry() async {
        let vm = DailyChartViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: FlakyCategoryRepository(failures: 1))
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        // E.g. the user comes back to the tab, which runs `configure` again.
        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }
}
