//
//  ExpenseFormViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 25/08/26.
//

import Testing
import Foundation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

@MainActor
struct ExpenseFormViewModelTests {

    private func makeBasket(categories: [Category]) -> CategoryBasket {
        CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: categories))
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
        let food = Category(id: 1, name: "Food")
        let expense = Expense(id: 1, categoryID: food.id, value: 25, locationName: "Starbucks")
        let vm = ExpenseFormViewModel(expense: expense)
        await vm.configure(with: makeBasket(categories: [food]))
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
        vm.selectedCategory = Category(id: 1, name: "Food")
        #expect(!vm.canSave)
    }

    @Test func canSaveIsFalseWithZeroValue() {
        let vm = ExpenseFormViewModel()
        vm.selectedCategory = Category(id: 1, name: "Food")
        vm.value = 0
        #expect(!vm.canSave)
    }

    @Test func canSaveIsTrueWithCategoryAndPositiveValue() {
        let vm = ExpenseFormViewModel()
        vm.selectedCategory = Category(id: 1, name: "Food")
        vm.value = 10
        #expect(vm.canSave)
    }

    // MARK: - configure(with:)

    @Test func configurePopulatesCategoriesSortedByName() async {
        let transport = Category(id: 2, name: "Transport")
        let food = Category(id: 1, name: "Food")
        let vm = ExpenseFormViewModel()
        await vm.configure(with: makeBasket(categories: [transport, food]))
        #expect(vm.categories.map(\.name) == ["Food", "Transport"])
    }

    @Test func configureWithEmptyRepoLeavesEmptyCategories() async {
        let vm = ExpenseFormViewModel()
        await vm.configure(with: makeBasket(categories: []))
        #expect(vm.categories.isEmpty)
    }

    // MARK: - leafCategories

    @Test func leafCategoriesExcludesParents() async {
        let parent = Category(id: 1, name: "Food")
        let child = Category(id: 3, name: "Restaurants", parentID: parent.id)
        let vm = ExpenseFormViewModel()
        await vm.configure(with: makeBasket(categories: [parent, child]))
        let leaves = vm.leafCategories()
        #expect(leaves.count == 1)
        #expect(leaves.first?.name == "Restaurants")
    }

    @Test func leafCategoriesIncludesAllWhenNoneHaveChildren() async {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let vm = ExpenseFormViewModel()
        await vm.configure(with: makeBasket(categories: [food, transport]))
        #expect(vm.leafCategories().count == 2)
    }
    
    // MARK: - Active categories
    @Test func activeCategoriesDoNotIncludeInactiveCategories() async {
        let food = Category(id: 1, name: "Food", isActive: true)
        let transport = Category(id: 2, name: "Transport", isActive: false)
        let vm = ExpenseFormViewModel()
        await vm.configure(with: makeBasket(categories: [food, transport]))
        #expect(vm.activeCategories().count == 1)
        #expect(vm.activeCategories().map{$0.id}.contains([1]))
        #expect(!(vm.activeCategories().map{$0.id}.contains(2)))

    }

    // MARK: - selectableCategories

    @Test func selectableCategoriesExcludesInactiveForNewExpense() async {
        let food = Category(id: 1, name: "Food", isActive: true)
        let transport = Category(id: 2, name: "Transport", isActive: false)
        let vm = ExpenseFormViewModel()
        await vm.configure(with: makeBasket(categories: [food, transport]))
        #expect(vm.selectableCategories().map(\.id) == [1])
    }

    @Test func selectableCategoriesKeepsInactiveCategoryOfEditedExpense() async {
        let food = Category(id: 1, name: "Food", isActive: true)
        let transport = Category(id: 2, name: "Transport", isActive: false)
        let other = Category(id: 3, name: "Other", isActive: false)
        let expense = Expense(id: 1, categoryID: transport.id, value: 10)
        let vm = ExpenseFormViewModel(expense: expense)
        await vm.configure(with: makeBasket(categories: [food, transport, other]))
        #expect(vm.selectableCategories().map(\.id) == [1, 2])
        #expect(vm.selectedCategory?.id == transport.id)
    }

    // MARK: - ExpenseBasket.latestCategoryID
    // These cover the lookup that ExpenseFormViewModel.resolveLocation() uses.

    @Test func latestCategoryIDReturnsNilWhenNoExpenses() {
        let basket = ExpenseBasket()
        #expect(basket.latestCategoryID(forLocationName: "Starbucks") == nil)
    }

    @Test func latestCategoryIDReturnsCategoryForMatchingLocation() {
        let food = Category(id: 1, name: "Food")
        let basket = ExpenseBasket(expenses: [
            Expense(id: 1, categoryID: food.id, value: 10, locationName: "Starbucks")
        ])
        #expect(basket.latestCategoryID(forLocationName: "Starbucks") == food.id)
    }

    @Test func latestCategoryIDReturnsMostRecentForLocation() {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let older = Expense(id: 1, categoryID: food.id, value: 10, datetime: Date.now.addingTimeInterval(-3600), locationName: "Airport")
        let newer = Expense(id: 2, categoryID: transport.id, value: 20, datetime: Date.now, locationName: "Airport")
        let basket = ExpenseBasket(expenses: [older, newer])
        #expect(basket.latestCategoryID(forLocationName: "Airport") == transport.id)
    }

    @Test func latestCategoryIDReturnsNilForUnknownLocation() {
        let food = Category(id: 1, name: "Food")
        let basket = ExpenseBasket(expenses: [
            Expense(id: 1, categoryID: food.id, value: 10, locationName: "Starbucks")
        ])
        #expect(basket.latestCategoryID(forLocationName: "McDonald's") == nil)
    }

    @Test func latestCategoryIDSearchesAcrossAllMonths() {
        let food = Category(id: 1, name: "Food")
        let pastDate = Calendar.current.date(byAdding: .month, value: -6, to: Date.now)!
        let basket = ExpenseBasket(expenses: [
            Expense(id: 1, categoryID: food.id, value: 10, datetime: pastDate, locationName: "OldPlace")
        ])
        #expect(basket.latestCategoryID(forLocationName: "OldPlace") == food.id)
    }

    // MARK: - save

    @Test func saveWhenEditingUpdatesExpenseInBasket() async throws {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let expense = Expense(id: 7, categoryID: food.id, details: "Lunch", value: 25)
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: [expense]))
        try await expenseBasket.loadIfNeeded()

        let vm = ExpenseFormViewModel(expense: expense)
        await vm.configure(with: makeBasket(categories: [food, transport]), expenseBasket: expenseBasket)
        vm.selectedCategory = transport
        vm.value = 40
        vm.details = "  Taxi  "
        let didSave = await vm.save()

        #expect(didSave)
        #expect(vm.errorMessage == nil)
        #expect(vm.isSaving == false)
        let saved = try #require(expenseBasket.expense(withID: 7))
        #expect(saved.categoryID == transport.id)
        #expect(saved.value == 40)
        #expect(saved.details == "Taxi")
        #expect(expenseBasket.expenses.count == 1)
    }

    @Test func saveWithoutConfigureReportsFailure() async {
        // Used to return silently, which the form treated as success and closed without saving.
        let vm = ExpenseFormViewModel(findPointOfInterest: { nil })
        vm.selectedCategory = Category(id: 1, name: "Food")
        vm.value = 10

        let didSave = await vm.save()

        #expect(didSave == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func saveFailureKeepsFormOpenWithError() async throws {
        let food = Category(id: 1, name: "Food")
        let expense = Expense(id: 7, categoryID: food.id, value: 25)
        let expenseBasket = ExpenseBasket(expenseRepository: FailingWriteExpenseRepository(expenses: [expense]))
        try await expenseBasket.loadIfNeeded()

        let vm = ExpenseFormViewModel(expense: expense)
        await vm.configure(with: makeBasket(categories: [food]), expenseBasket: expenseBasket)
        vm.value = 99

        let didSave = await vm.save()

        #expect(didSave == false)
        #expect(vm.errorMessage == APIError.network.errorDescription)
        #expect(vm.isSaving == false)
        // Nothing changed locally either.
        #expect(expenseBasket.expense(withID: 7)?.value == 25)
    }

    @Test func cannotSaveWhileSaving() {
        let vm = ExpenseFormViewModel()
        vm.selectedCategory = Category(id: 1, name: "Food")
        vm.value = 10
        #expect(vm.canSave)

        vm.isSaving = true
        #expect(vm.canSave == false)
    }
}

/// Expense repository that loads fine but whose writes fail, like a network error on save.
@MainActor
private final class FailingWriteExpenseRepository: @MainActor ExpenseRepository {
    private let expenses: [Expense]

    init(expenses: [Expense]) {
        self.expenses = expenses
    }

    func fetchAll() async throws -> [Expense] { expenses }
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Expense] { expenses }
    func create(_ draft: ExpenseDraft) async throws -> Expense { throw APIError.network }
    func update(_ expense: Expense) async throws -> Expense { throw APIError.network }
    func delete(_ expense: Expense) async throws { throw APIError.network }
}
