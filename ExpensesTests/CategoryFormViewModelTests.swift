//
//  CategoryFormViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

@MainActor
struct CategoryFormViewModelTests {

    // Food → Restaurants, Groceries; Transport (no children)
    private let food = Category(id: 1, name: "Food")
    private let restaurants = Category(id: 2, name: "Restaurants", parentID: 1)
    private let groceries = Category(id: 3, name: "Groceries", parentID: 1)
    private let transport = Category(id: 4, name: "Transport")

    private var all: [Category] { [food, restaurants, groceries, transport] }

    private func makeViewModel(editing category: Category? = nil, categories: [Category]? = nil) async -> CategoryFormViewModel {
        let vm = CategoryFormViewModel(category: category)
        await vm.configure(with: CategoryBasket(categories: categories ?? all))
        return vm
    }

    // MARK: - Two-level rule

    @Test func newCategoryOnlyOffersRootCategoriesAsParents() async {
        let vm = await makeViewModel()

        #expect(vm.canHaveParent)
        #expect(Set(vm.availableParents.map(\.id)) == [food.id, transport.id])
    }

    @Test func categoryIsNeverOfferedAsItsOwnParent() async {
        let vm = await makeViewModel(editing: transport)

        #expect(vm.availableParents.map(\.id) == [food.id])
    }

    @Test func categoryWithSubcategoriesCannotGetAParent() async {
        let vm = await makeViewModel(editing: food)

        #expect(vm.canHaveParent == false)
        #expect(vm.availableParents.isEmpty)
    }

    @Test func ownSubcategoriesAreNeverOfferedAsParents() async {
        // This used to allow Food → Restaurants → Food, which hid both from the grid.
        let vm = await makeViewModel(editing: food)

        #expect(!vm.availableParents.contains(restaurants))
        #expect(!vm.availableParents.contains(groceries))
    }

    @Test func subcategoryCanMoveToAnotherRoot() async {
        let vm = await makeViewModel(editing: restaurants)

        #expect(vm.canHaveParent)
        #expect(Set(vm.availableParents.map(\.id)) == [food.id, transport.id])
        #expect(vm.parent == food)
    }

    @Test func legacyNonRootParentStaysSelectable() async {
        // Created before the two-level rule: Food → Restaurants → Fast Food.
        let fastFood = Category(id: 5, name: "Fast Food", parentID: restaurants.id)
        let vm = await makeViewModel(editing: fastFood, categories: all + [fastFood])

        #expect(vm.parent == restaurants)
        #expect(vm.availableParents.contains(restaurants))
    }
}
