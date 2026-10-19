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
        await vm.configure(with: CategoryBasket(categoryRepository: FlakyCategoryRepository(failures: 1)))
        #expect(vm.loadingState == .failed)
    }

    @Test func configureRecoversOnRetry() async {
        let vm = CategoriesViewModel()
        let basket = CategoryBasket(categoryRepository: FlakyCategoryRepository(failures: 1))

        await vm.configure(with: basket)
        #expect(vm.loadingState == .failed)

        // E.g. the user comes back to the tab, which runs `configure` again.
        await vm.configure(with: basket)
        #expect(vm.loadingState == .success)
        #expect(!vm.categories.isEmpty)
    }

    @Test func refreshFailureShowsError() async {
        let vm = CategoriesViewModel()
        // First load succeeds, the pull-to-refresh fails.
        let basket = CategoryBasket(categoryRepository: FlakyCategoryRepository(failures: 1, succeedFirst: true))

        await vm.configure(with: basket)
        #expect(vm.loadingState == .success)

        await vm.refresh()
        #expect(vm.loadingState == .failed)
    }
}

private struct LoadError: Error {}

/// Category repository that fails `failures` fetches (optionally after one successful fetch).
@MainActor
private final class FlakyCategoryRepository: @MainActor CategoryRepository {
    private var failuresRemaining: Int
    private var succeedNext: Bool

    init(failures: Int, succeedFirst: Bool = false) {
        self.failuresRemaining = failures
        self.succeedNext = succeedFirst
    }

    func fetchAll() async throws -> [Category] {
        if succeedNext {
            succeedNext = false
        } else if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw LoadError()
        }
        return [Category(id: 1, name: "Food")]
    }

    func create(_ draft: CategoryDraft) async throws -> Category { throw LoadError() }
    func update(_ category: Category) async throws -> Category { throw LoadError() }
    func delete(_ category: Category) async throws { throw LoadError() }
}
