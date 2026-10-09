//
//  CategoriesViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 10/08/26.
//

import Testing
@testable import Expenses

@MainActor
struct CategoriesViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(with categories: [Category] = []) async -> CategoriesViewModel {
        let vm = CategoriesViewModel()
        let mockRepo = MockCategoryDataProvider(categories: categories)
        await vm.configure(with: CategoryBasket(categoryRepository: mockRepo))
        return vm
    }

    // MARK: - Initial State

    @Test func initialState() {
        let vm = CategoriesViewModel()
        #expect(vm.showingForm == false)
        #expect(vm.categoryToEdit == nil)
        #expect(vm.categories.isEmpty)
    }

    // MARK: - configure

    @Test func configurePopulatesCategories() async {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let vm = await makeViewModel(with: [food, transport])

        #expect(vm.categories.count == 2)
    }

    @Test func configureWithEmptyRepoLeavesEmptyCategories() async {
        let vm = await makeViewModel()
        #expect(vm.categories.isEmpty)
    }

    // MARK: - rootCategories

    @Test func rootCategoriesReturnsOnlyTopLevel() async {
        let parent = Category(id: 1, name: "Food")
        let child = Category(id: 3, name: "Restaurants", parentID: parent.id)
        let vm = await makeViewModel(with: [parent, child])

        let roots = vm.rootCategories()
        #expect(roots.count == 1)
        #expect(roots.first?.name == "Food")
    }

    @Test func rootCategoriesIsEmptyWhenAllHaveParents() async {
        let parent = Category(id: 1, name: "Food")
        let child = Category(id: 3, name: "Restaurants", parentID: parent.id)
        // Only inserting children — not the parent itself
        let vm = await makeViewModel(with: [child])

        let roots = vm.rootCategories()
        #expect(roots.isEmpty)
    }

    @Test func rootCategoriesReturnsAllWhenNoneHaveParent() async {
        let food = Category(id: 1, name: "Food")
        let transport = Category(id: 2, name: "Transport")
        let vm = await makeViewModel(with: [food, transport])

        let roots = vm.rootCategories()
        #expect(roots.count == 2)
    }
}
