//
//  ExpensesListViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 25/08/26.
//

import Testing
import Foundation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

struct ExpensesListViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(expenses: [Expense] = [], categories: [Category] = []) async -> ExpensesListViewModel {
        let vm = ExpensesListViewModel()
        // Baskets without a repository load right away with the given data.
        await vm.configure(with: CategoryBasket(categories: categories), expenseBasket: ExpenseBasket(expenses: expenses))
        return vm
    }

    // MARK: - latestCategory

    @Test func latestCategoryReturnsNilWhenNoExpenses() async {
        let vm = await makeViewModel()
        let result = await vm.latestCategory(forLocationName: "Starbucks")
        #expect(result == nil)
    }

    @Test func latestCategoryReturnsMatch() async {
        let food = Category(id: 1, name: "Food")
        let expense = Expense(id: 1, categoryID: food.id, value: 10, locationName: "Starbucks")
        let vm = await makeViewModel(expenses: [expense], categories: [food])

        let result = await vm.latestCategory(forLocationName: "Starbucks")
        #expect(result?.name == "Food")
    }

    @Test func latestCategoryReturnsMostRecentWhenMultipleMatch() async {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let older = Expense(id: 1, categoryID: food.id, value: 10, datetime: .now.addingTimeInterval(-3600), locationName: "Airport")
        let newer = Expense(id: 2, categoryID: transport.id, value: 20, datetime: .now, locationName: "Airport")
        let vm = await makeViewModel(expenses: [older, newer], categories: [food, transport])

        let result = await vm.latestCategory(forLocationName: "Airport")
        #expect(result?.name == "Transport")
    }

    @Test func latestCategoryReturnsNilWhenLocationNotFound() async {
        let food = Category(id: 1, name: "Food")
        let expense = Expense(id: 1, categoryID: food.id, value: 10, locationName: "Starbucks")
        let vm = await makeViewModel(expenses: [expense], categories: [food])

        let result = await vm.latestCategory(forLocationName: "McDonald's")
        #expect(result == nil)
    }

    // MARK: - Category filter

    @Test func filterBySelectedCategoryIncludesSubcategories() async {
        let food = Category(id: 1, name: "Food")
        let restaurants = Category(id: 3, name: "Restaurants", parentID: food.id)
        let transport = Category(id: 2, name: "Transport")
        let vm = await makeViewModel(
            expenses: [
                Expense(id: 1, categoryID: food.id, value: 10),
                Expense(id: 2, categoryID: restaurants.id, value: 20),
                Expense(id: 3, categoryID: transport.id, value: 30)
            ],
            categories: [food, restaurants, transport]
        )
        vm.filter.category = food

        #expect(vm.filteredExpenses().map(\.value).sorted() == [10, 20])
    }

    // MARK: - Month filter

    @Test func latestCategorySearchesOutsideSelectedMonth() async {
        let food = Category(id: 1, name: "Food")
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: .now)!
        let oldExpense = Expense(id: 1, categoryID: food.id, value: 15, datetime: pastDate, locationName: "OldPlace")

        let vm = ExpensesListViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: [food])),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: [oldExpense]))
        )
        // `expenses` only holds the current month — OldPlace won't be present
        #expect(vm.expenses.filter { $0.locationName == "OldPlace" }.isEmpty)

        let result = await vm.latestCategory(forLocationName: "OldPlace")
        #expect(result?.name == "Food")
    }

    // MARK: - Writes

    @Test func deleteRemovesExpenseFromBasket() async {
        let food = Category(id: 1, name: "Food")
        let lunch = Expense(id: 1, categoryID: food.id, value: 10)
        let dinner = Expense(id: 2, categoryID: food.id, value: 20)
        let basket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: [lunch, dinner]))
        let vm = ExpensesListViewModel()
        await vm.configure(with: CategoryBasket(categories: [food]), expenseBasket: basket)

        await vm.deleteExpenses(at: IndexSet(integer: 0), from: [lunch, dinner])

        #expect(basket.expenses.map(\.id) == [2])
        #expect(vm.errorMessage == nil)
    }

    @Test func toggleExtraordinaryUpdatesExpenseInBasket() async {
        let food = Category(id: 1, name: "Food")
        let lunch = Expense(id: 1, categoryID: food.id, value: 10)
        let basket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: [lunch]))
        let vm = ExpensesListViewModel()
        await vm.configure(with: CategoryBasket(categories: [food]), expenseBasket: basket)

        await vm.toggleExtraordinary(lunch)

        #expect(basket.expense(withID: 1)?.extraordinary == true)
    }

    // MARK: - Empty states

    @Test func noExpensesAtAll() async {
        let vm = await makeViewModel()

        #expect(vm.expenses.isEmpty)
        #expect(vm.hasAnyExpenses == false)
    }

    @Test func emptyMonthWithExpensesInOtherMonths() async throws {
        // The selected month defaults to the current one; this expense is two months earlier.
        let twoMonthsAgo = try #require(Calendar.current.date(byAdding: .month, value: -2, to: .now))
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 1, value: 10, datetime: twoMonthsAgo)])

        #expect(vm.expenses.isEmpty)
        #expect(vm.hasAnyExpenses)
    }

    @Test func monthWithExpenses() async {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 1, value: 10)])

        #expect(!vm.expenses.isEmpty)
        #expect(vm.hasAnyExpenses)
    }
}
