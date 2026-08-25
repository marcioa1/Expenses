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

@MainActor
struct ExpensesListViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(expenses: [Expense] = []) -> ExpensesListViewModel {
        let vm = ExpensesListViewModel()
        vm.expenses = expenses
        return vm
    }

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Expense.self, Category.self, configurations: config)
    }

    // MARK: - In-memory path

    @Test func latestCategoryReturnsNilWhenNoExpenses() async {
        let vm = makeViewModel()
        let result = await vm.latestCategory(forLocationName: "Starbucks")
        #expect(result == nil)
    }

    @Test func latestCategoryReturnsMatchFromMemory() async {
        let food = Category(name: "Food")
        let expense = Expense(category: food, value: 10, locationName: "Starbucks")
        let vm = makeViewModel(expenses: [expense])

        let result = await vm.latestCategory(forLocationName: "Starbucks")
        #expect(result?.name == "Food")
    }

    @Test func latestCategoryReturnsMostRecentWhenMultipleMatchInMemory() async {
        let food = Category(name: "Food")
        let transport = Category(name: "Transport")
        let older = Expense(category: food, value: 10, datetime: .now.addingTimeInterval(-3600), locationName: "Airport")
        let newer = Expense(category: transport, value: 20, datetime: .now, locationName: "Airport")
        let vm = makeViewModel(expenses: [older, newer])

        let result = await vm.latestCategory(forLocationName: "Airport")
        #expect(result?.name == "Transport")
    }

    @Test func latestCategoryReturnsNilWhenLocationNotFoundInMemory() async {
        let food = Category(name: "Food")
        let expense = Expense(category: food, value: 10, locationName: "Starbucks")
        let vm = makeViewModel(expenses: [expense])

        let result = await vm.latestCategory(forLocationName: "McDonald's")
        #expect(result == nil)
    }

    // MARK: - DB fallback path

    @Test func latestCategoryFallsBackToDBWhenNotInCurrentMonth() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let food = Category(name: "Food")
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: .now)!
        let oldExpense = Expense(category: food, value: 15, datetime: pastDate, locationName: "OldPlace")
        context.insert(food)
        context.insert(oldExpense)
        try context.save()

        let vm = ExpensesListViewModel()
        await vm.configure(modelContext: context)
        // expenses only holds current month — OldPlace won't be present
        #expect(vm.expenses.filter { $0.locationName == "OldPlace" }.isEmpty)

        let result = await vm.latestCategory(forLocationName: "OldPlace")
        #expect(result?.name == "Food")
    }
}
