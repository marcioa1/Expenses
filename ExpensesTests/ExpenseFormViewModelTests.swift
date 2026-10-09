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
        return try ModelContainer(for: Expense.self, configurations: config)
    }

    // MARK: - Initial state

    @Test func initWithoutExpenseIsNotEditing() {
        let vm = ExpenseFormViewModel()
        #expect(!vm.isEditing)
        #expect(vm.selectedCategory == nil)
        #expect(vm.value == nil)
        #expect(vm.details == "")
    }

    @Test func initWithExpenseIsEditing() async {
        let food = Category(name: "Food")
        let expense = Expense(categoryID: food.id, value: 25, locationName: "Starbucks")
        let vm = ExpenseFormViewModel(expense: expense)
        await vm.configure(with: MockCategoryDataProvider(categories: [food]))
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
        let child = Category(name: "Restaurants", parentID: parent.id)
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

    // MARK: - ExpenseLocalDataProvider.latestCategoryID
    // These cover the DB path that ExpenseFormViewModel.resolveLocation() uses.

    @Test func latestCategoryIDReturnsNilWhenNoExpenses() throws {
        let container = try makeContainer()
        let provider = ExpenseLocalDataProvider(modelContext: ModelContext(container))
        #expect(try provider.latestCategoryID(forLocationName: "Starbucks") == nil)
    }

    @Test func latestCategoryIDReturnsCategoryForMatchingLocation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        context.insert(Expense(categoryID: food.id, value: 10, locationName: "Starbucks"))
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategoryID(forLocationName: "Starbucks")
        #expect(result == food.id)
    }

    @Test func latestCategoryIDReturnsMostRecentForLocation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        let transport = Category(name: "Transport")
        let older = Expense(categoryID: food.id, value: 10, datetime: Date.now.addingTimeInterval(-3600), locationName: "Airport")
        let newer = Expense(categoryID: transport.id, value: 20, datetime: Date.now, locationName: "Airport")
        context.insert(older)
        context.insert(newer)
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategoryID(forLocationName: "Airport")
        #expect(result == transport.id)
    }

    @Test func latestCategoryIDReturnsNilForUnknownLocation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        context.insert(Expense(categoryID: food.id, value: 10, locationName: "Starbucks"))
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategoryID(forLocationName: "McDonald's")
        #expect(result == nil)
    }

    @Test func latestCategoryIDSearchesAcrossAllMonths() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let food = Category(name: "Food")
        let pastDate = Calendar.current.date(byAdding: .month, value: -6, to: Date.now)!
        context.insert(Expense(categoryID: food.id, value: 10, datetime: pastDate, locationName: "OldPlace"))
        try context.save()

        let result = try ExpenseLocalDataProvider(modelContext: context).latestCategoryID(forLocationName: "OldPlace")
        #expect(result == food.id)
    }
}
