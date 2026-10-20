//
//  SummaryViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

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
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider(fetchError: APIError.network)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureFailsWhenOnlyExpensesFail() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider(fetchError: APIError.network))
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

    // MARK: - Category breakdown

    private let food = Expenses.Category(id: 1, name: "Food")
    private let restaurants = Expenses.Category(id: 2, name: "Restaurants", parentID: 1)
    private let transport = Expenses.Category(id: 3, name: "Transport")

    /// A view model on the current month, backed by in-memory baskets that load right away.
    private func makeViewModel(expenses: [Expense]) async -> SummaryViewModel {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categories: [food, restaurants, transport]),
            expenseBasket: ExpenseBasket(expenses: expenses)
        )
        return vm
    }

    @Test func groupsSubcategoriesUnderTheirRootLargestFirst() async throws {
        let vm = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: food.id, value: 10),
            Expense(id: 2, categoryID: restaurants.id, value: 30),
            Expense(id: 3, categoryID: transport.id, value: 25),
        ])

        let groups = vm.categoryGroups
        #expect(groups.map(\.parent.id) == [food.id, transport.id])   // 40 before 25.

        let foodGroup = try #require(groups.first)
        #expect(foodGroup.total == 40)
        #expect(foodGroup.subtotals.map(\.category.id) == [restaurants.id, food.id])
        #expect(foodGroup.hasChildren)
    }

    @Test func groupWithOnlyParentExpensesHasNoChildren() async throws {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: transport.id, value: 25)])

        let group = try #require(vm.categoryGroups.first)
        #expect(group.total == 25)
        #expect(!group.hasChildren)
    }

    @Test func expensesWithUnknownCategoryAreLeftOut() async {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 99, value: 10)])
        #expect(vm.categoryGroups.isEmpty)
    }
}
