//
//  ExpenseFormViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 25/08/26.
//

import Testing
import SwiftData
import Foundation
@testable import Expenses

@MainActor
struct ExpenseFormViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Expense.self, Category.self, configurations: config)
    }

    // MARK: - Initial state

    @Test func initWithoutExpenseIsNotEditing() {
        let vm = ExpenseFormViewModel()
        #expect(!vm.isEditing)
        #expect(vm.selectedCategory == nil)
        #expect(vm.value == nil)
        #expect(vm.details == "")
    }

    @Test func initWithExpenseIsEditing() {
        let food = Category(name: "Food")
        let expense = Expense(category: food, value: 25, locationName: "Starbucks")
        let vm = ExpenseFormViewModel(expense: expense)
        #expect(vm.isEditing)
        #expect(vm.selectedCategory?.name == "Food")
        #expect(vm.value == 25)
        #expect(vm.locationName == "Starbucks")
    }

    // MARK: - canSave

    @Test func canSaveIsFalseWithoutCategoryAndValue() {
        let vm = ExpenseFormViewModel()
        #expect(!vm.canSave)
    }

    @Test func canSaveIsFalseWithCategoryButNoValue() {
        let vm = ExpenseFormViewModel()
        vm.selectedCategory = Category(name: "Food")
        #expect(!vm.canSave)
    }

    @Test func canSaveIsFalseWithZeroValue() {
        let vm = ExpenseFormViewModel()
        vm.selectedCategory = Category(name: "Food")
        vm.value = 0
        #expect(!vm.canSave)
    }

    @Test func canSaveIsTrueWithCategoryAndPositiveValue() {
        let vm = ExpenseFormViewModel()
        vm.selectedCategory = Category(name: "Food")
        vm.value = 10
        #expect(vm.canSave)
    }

    // MARK: - configure(with:)

    @Test func configurePopulatesCategoriesSortedByName() async {
        let transport = Category(name: "Transport")
        let food = Category(name: "Food")
        let vm = ExpenseFormViewModel()
        await vm.configure(with: MockCategoryDataProvider(categories: [transport, food]))
        #expect(vm.categories.map(\.name) == ["Food", "Transport"])
    }

    @Test func configureWithEmptyRepoLeavesEmptyCategories() async {
        let vm = ExpenseFormViewModel()
        await vm.configure(with: MockCategoryDataProvider(categories: []))
        #expect(vm.categories.isEmpty)
    }

    // MARK: - leafCategories

    @Test func leafCategoriesExcludesParents() async {
        let parent = Category(name: "Food")
        let child = Category(name: "Restaurants", parent: parent)
        let vm = ExpenseFormViewModel()
        await vm.configure(with: MockCategoryDataProvider(categories: [parent, child]))
        let leaves = vm.leafCategories()
        #expect(leaves.count == 1)
        #expect(leaves.first?.name == "Restaurants")
    }

    @Test func leafCategoriesIncludesAllWhenNoneHaveChildren() async {
        let food = Category(name: "Food")
        let transport = Category(name: "Transport")
        let vm = ExpenseFormViewModel()
        await vm.configure(with: MockCategoryDataProvider(categories: [food, transport]))
        #expect(vm.leafCategories().count == 2)
    }

    // MARK: - ExpenseLocalDataProvider.latestCategory
    // These cover the DB path that ExpenseFormViewModel.resolveLocation() uses.

    @Test func latestCategoryReturnsNilWhenNoExpenses() throws {
        let container = try makeContainer()
        let provider = ExpenseLocalDataProvider(modelContext: ModelContext(container))
        #expect(try provider.latestCategory(forLocationName: "Starbucks") == nil)
    }

    @Test func latestCategoryReturnsCategoryForMatchingLocation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        context.insert(food)
        context.insert(Expense(category: food, value: 10, locationName: "Starbucks"))
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategory(forLocationName: "Starbucks")
        #expect(result?.name == "Food")
    }

    @Test func latestCategoryReturnsMostRecentForLocation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        let transport = Category(name: "Transport")
        let older = Expense(category: food, value: 10, datetime: Date.now.addingTimeInterval(-3600), locationName: "Airport")
        let newer = Expense(category: transport, value: 20, datetime: Date.now, locationName: "Airport")
        context.insert(food)
        context.insert(transport)
        context.insert(older)
        context.insert(newer)
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategory(forLocationName: "Airport")
        #expect(result?.name == "Transport")
    }

    @Test func latestCategoryReturnsNilForUnknownLocation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        context.insert(food)
        context.insert(Expense(category: food, value: 10, locationName: "Starbucks"))
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategory(forLocationName: "McDonald's")
        #expect(result == nil)
    }

    @Test func latestCategorySearchesAcrossAllMonths() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        let pastDate = Calendar.current.date(byAdding: .month, value: -6, to: Date.now)!
        context.insert(food)
        context.insert(Expense(category: food, value: 10, datetime: pastDate, locationName: "OldPlace"))
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategory(forLocationName: "OldPlace")
        #expect(result?.name == "Food")
    }
}
