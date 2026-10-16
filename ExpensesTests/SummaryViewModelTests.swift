//
//  SummaryViewModelTests.swift
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

/// Category repository whose fetch always fails.
@MainActor
private final class FailingCategoryRepository: @MainActor CategoryRepository {
    func fetchAll() async throws -> [Category] { throw LoadError() }
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
struct SummaryViewModelTests {

    @Test func configureSucceedsWhenBothLoadsSucceed() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .success)
    }

    @Test func configureFailsWhenOnlyCategoriesFail() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: FailingCategoryRepository()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureFailsWhenOnlyExpensesFail() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: FailingExpenseRepository())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func changingMonthKeepsLoadedState() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        vm.selectedMonthIndex = 0
        #expect(vm.loadingState == .success)
    }
}
