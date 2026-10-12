//
//  ExpensesListViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 25/08/26.
//

import Testing
import SwiftData
import Foundation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

@MainActor
struct ExpensesListViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(expenses: [Expense] = [], categories: [Category] = []) -> ExpensesListViewModel {
        let vm = ExpensesListViewModel()
        vm.expenses = expenses
        vm.categoryBasket = CategoryBasket(categories: categories)
        return vm
    }

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Expense.self, configurations: config)
    }

    // MARK: - In-memory path

    @Test func latestCategoryReturnsNilWhenNoExpenses() async {
        let vm = makeViewModel()
        let result = await vm.latestCategory(forLocationName: "Starbucks")
        #expect(result == nil)
    }

    @Test func latestCategoryReturnsMatchFromMemory() async {
        let food = Category(id: 1, name: "Food")
        let expense = Expense(categoryID: food.id, value: 10, locationName: "Starbucks")
        let vm = makeViewModel(expenses: [expense], categories: [food])

        let result = await vm.latestCategory(forLocationName: "Starbucks")
        #expect(result?.name == "Food")
    }

    @Test func latestCategoryReturnsMostRecentWhenMultipleMatchInMemory() async {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let older = Expense(categoryID: food.id, value: 10, datetime: .now.addingTimeInterval(-3600), locationName: "Airport")
        let newer = Expense(categoryID: transport.id, value: 20, datetime: .now, locationName: "Airport")
        let vm = makeViewModel(expenses: [older, newer], categories: [food, transport])

        let result = await vm.latestCategory(forLocationName: "Airport")
        #expect(result?.name == "Transport")
    }

    @Test func latestCategoryReturnsNilWhenLocationNotFoundInMemory() async {
        let food = Category(id: 1, name: "Food")
        let expense = Expense(categoryID: food.id, value: 10, locationName: "Starbucks")
        let vm = makeViewModel(expenses: [expense], categories: [food])

        let result = await vm.latestCategory(forLocationName: "McDonald's")
        #expect(result == nil)
    }

    // MARK: - Category filter

    @Test func filterBySelectedCategoryIncludesSubcategories() {
        let food = Category(id: 1, name: "Food")
        let restaurants = Category(id: 3, name: "Restaurants", parentID: food.id)
        let transport = Category(id: 2, name: "Transport")
        let vm = makeViewModel(
            expenses: [
                Expense(categoryID: food.id, value: 10),
                Expense(categoryID: restaurants.id, value: 20),
                Expense(categoryID: transport.id, value: 30)
            ],
            categories: [food, restaurants, transport]
        )
        vm.selectedCategory = food

        #expect(vm.filteredExpenses().map(\.value).sorted() == [10, 20])
    }

    // MARK: - DB fallback path

    @Test func latestCategoryFallsBackToDBWhenNotInCurrentMonth() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let food = Category(id: 1, name: "Food")
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: .now)!
        let oldExpense = Expense(categoryID: food.id, value: 15, datetime: pastDate, locationName: "OldPlace")
        context.insert(oldExpense)
        try context.save()

        let vm = ExpensesListViewModel()
        await vm.configure(modelContext: context, categoryBasket: CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: [food])))
        // expenses only holds current month — OldPlace won't be present
        #expect(vm.expenses.filter { $0.locationName == "OldPlace" }.isEmpty)

        let result = await vm.latestCategory(forLocationName: "OldPlace")
        #expect(result?.name == "Food")
    }
}
