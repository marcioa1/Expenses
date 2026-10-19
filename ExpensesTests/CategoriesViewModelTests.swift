//
//  CategoriesViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 10/08/26.
//

import Testing
@testable import Expenses

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

    // MARK: - Loading state

    @Test func startsLoading() {
        #expect(CategoriesViewModel().loadingState == .loading)
    }

    @Test func configureSucceeds() async {
        let vm = await makeViewModel(with: [Category(id: 1, name: "Food")])
        #expect(vm.loadingState == .success)
    }

    @Test func configureSucceedsWithNoCategories() async {
        // An empty list is a successful load; the view shows its empty state, not an error.
        let vm = await makeViewModel()
        #expect(vm.loadingState == .success)
    }

    @Test func configureFailsWhenFetchFails() async {
        let vm = CategoriesViewModel()
        await vm.configure(with: CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1)))
        #expect(vm.loadingState == .failed)
    }

    @Test func configureRecoversOnRetry() async {
        let vm = CategoriesViewModel()
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1))

        await vm.configure(with: basket)
        #expect(vm.loadingState == .failed)

        // E.g. the user comes back to the tab, which runs `configure` again.
        await vm.configure(with: basket)
        #expect(vm.loadingState == .success)
        #expect(!vm.categories.isEmpty)
    }

    @Test func refreshFailureKeepsCategoriesAndShowsMessage() async {
        let vm = CategoriesViewModel()
        let repository = MockCategoryDataProvider()
        let basket = CategoryBasket(categoryRepository: repository)

        // First load succeeds…
        await vm.configure(with: basket)
        #expect(vm.loadingState == .success)
        #expect(vm.errorMessage == nil)

        // …then the pull-to-refresh fails.
        repository.fetchError = APIError.network
        await vm.refresh()
        // The screen keeps showing the categories it already had and tells the user why they didn't change.
        #expect(vm.loadingState == .success)
        #expect(!vm.categories.isEmpty)
        #expect(vm.errorMessage != nil)
    }
}
