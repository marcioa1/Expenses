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

/// Expense repository whose first `fetchAll()` fails and later ones succeed.
@MainActor
private final class FlakyExpenseRepository: @MainActor ExpenseRepository {
    private var failuresRemaining: Int

    init(failures: Int = 1) {
        self.failuresRemaining = failures
    }

    func fetchAll() async throws -> [Expense] {
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw LoadError()
        }
        return []
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
}
