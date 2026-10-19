//
//  LoadingStateRecoveryTests.swift
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

/// Category repository whose first `fetchAll()` fails and later ones succeed.
@MainActor
private final class FlakyCategoryRepository: @MainActor CategoryRepository {
    private var failuresRemaining: Int
    private let categories: [Category]

    init(failures: Int = 1, categories: [Category] = [Category(id: 1, name: "Food")]) {
        self.failuresRemaining = failures
        self.categories = categories
    }

    func fetchAll() async throws -> [Category] {
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw LoadError()
        }
        return categories
    }

    func create(_ draft: CategoryDraft) async throws -> Category { throw LoadError() }
    func update(_ category: Category) async throws -> Category { throw LoadError() }
    func delete(_ category: Category) async throws { throw LoadError() }
}

/// Expense repository whose first `failures` fetches fail and later ones succeed.
/// With `succeedFirst`, one successful fetch comes before the failures (a load, then a failed refresh).
@MainActor
private final class FlakyExpenseRepository: @MainActor ExpenseRepository {
    private var failuresRemaining: Int
    private var succeedNext: Bool
    private let expenses: [Expense]

    init(failures: Int = 1, succeedFirst: Bool = false, expenses: [Expense] = []) {
        self.failuresRemaining = failures
        self.succeedNext = succeedFirst
        self.expenses = expenses
    }

    func fetchAll() async throws -> [Expense] {
        if succeedNext {
            succeedNext = false
        } else if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw LoadError()
        }
        return expenses
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [Expense] { try await fetchAll() }
    func create(_ draft: ExpenseDraft) async throws -> Expense { throw LoadError() }
    func update(_ expense: Expense) async throws -> Expense { throw LoadError() }
    func delete(_ expense: Expense) async throws { throw LoadError() }
}

@MainActor
struct LoadingStateRecoveryTests {

    // MARK: - ExpensesListViewModel

    @Test func expensesListRecoversWhenConfigureIsRetried() async {
        let vm = ExpensesListViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: FlakyCategoryRepository())
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }

    @Test func expensesListRefreshRetriesFailedCategories() async {
        let vm = ExpensesListViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: FlakyCategoryRepository())
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
        let expenseBasket = ExpenseBasket(expenseRepository: FlakyExpenseRepository(failures: 2))

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        await vm.refreshExpenses()
        #expect(vm.loadingState == .failed)
    }

    @Test func expensesListRefreshFailureKeepsDataAndShowsMessage() async {
        let vm = ExpensesListViewModel()
        let lunch = Expense(id: 1, categoryID: 1, value: 10)
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        let expenseBasket = ExpenseBasket(
            expenseRepository: FlakyExpenseRepository(failures: 1, succeedFirst: true, expenses: [lunch])
        )

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
        #expect(vm.errorMessage == nil)

        // Pull-to-refresh fails: the list keeps what it had and tells the user it couldn't refresh.
        await vm.refreshExpenses()
        #expect(vm.loadingState == .success)
        #expect(vm.expenses.map(\.id) == [1])
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Shared state across tabs

    @Test func recoveryOnOneTabClearsTheErrorOnAnother() async {
        // Two tabs sharing the same baskets, as in the app.
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider())
        let expenseBasket = ExpenseBasket(expenseRepository: FlakyExpenseRepository(failures: 1))
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
        let expenseBasket = ExpenseBasket(expenseRepository: FlakyExpenseRepository(failures: 2))
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
        let expenseBasket = ExpenseBasket(expenseRepository: FlakyExpenseRepository())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }

    @Test func monthlyGridFailsWhenCategoriesFail() async {
        let vm = MonthlyGridViewModel()
        #expect(vm.loadingState == .loading)

        await vm.configure(
            with: CategoryBasket(categoryRepository: FlakyCategoryRepository(failures: 1)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )

        #expect(vm.loadingState == .failed)
    }
}
