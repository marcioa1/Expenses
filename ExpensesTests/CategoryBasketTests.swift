//
//  CategoryBasketTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Testing
@testable import Expenses

@MainActor
struct CategoryBasketTests {

    @Test func loadIfNeededFetchesCategories() async throws {
        let food = Category(id: 1, name: "Food")
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: [food]))

        try await basket.loadIfNeeded()

        #expect(basket.hasLoaded)
        #expect(basket.categories.map(\.name) == ["Food"])
    }

    @Test func loadIfNeededDoesNotRefetchOnceLoaded() async throws {
        let repository = MockCategoryDataProvider(categories: [Category(id: 1, name: "Food")])
        let basket = CategoryBasket(categoryRepository: repository)
        try await basket.loadIfNeeded()

        // Change the server-side data behind the basket's back.
        _ = try await repository.create(CategoryDraft(name: "Transport"))
        try await basket.loadIfNeeded()

        #expect(basket.categories.map(\.name) == ["Food"])
    }

    @Test func getAllCategoriesAlwaysRefetches() async throws {
        let repository = MockCategoryDataProvider(categories: [Category(id: 1, name: "Food")])
        let basket = CategoryBasket(categoryRepository: repository)
        try await basket.loadIfNeeded()

        _ = try await repository.create(CategoryDraft(name: "Transport"))
        try await basket.getAllCategories()

        #expect(basket.categories.count == 2)
    }

    @Test func createAddsCategorySortedByName() async throws {
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: []))
        try await basket.create(CategoryDraft(name: "Transport"))
        try await basket.create(CategoryDraft(name: "Food"))

        #expect(basket.categories.map(\.name) == ["Food", "Transport"])
    }

    @Test func createStoresServerAssignedID() async throws {
        let food = Category(id: 7, name: "Food")
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: [food]), categories: [food])

        try await basket.create(CategoryDraft(name: "Restaurants", parentID: food.id))

        let created = try #require(basket.categories.first { $0.name == "Restaurants" })
        #expect(created.id == 8)
        #expect(created.parentID == food.id)
    }

    @Test func updateReplacesCategory() async throws {
        let food = Category(id: 1, name: "Food")
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: [food]), categories: [food])

        var renamed = food
        renamed.name = "Groceries"
        try await basket.update(renamed)

        #expect(basket.categories.map(\.name) == ["Groceries"])
    }

    @Test func deleteRemovesCategory() async throws {
        let food = Category(id: 1, name: "Food")
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: [food]), categories: [food])

        try await basket.delete(food)

        #expect(basket.categories.isEmpty)
    }

    // MARK: - Two-level rule (enforced by the basket, whatever screen calls it)

    /// Food → Restaurants; Transport (no children).
    private func makeHierarchy() -> (basket: CategoryBasket, food: Category, restaurants: Category, transport: Category) {
        let food = Category(id: 1, name: "Food")
        let restaurants = Category(id: 2, name: "Restaurants", parentID: food.id)
        let transport = Category(id: 3, name: "Transport")
        let all = [food, restaurants, transport]
        let basket = CategoryBasket(categoryRepository: MockCategoryDataProvider(categories: all), categories: all)
        return (basket, food, restaurants, transport)
    }

    @Test func updateRejectsCycle() async {
        let (basket, food, restaurants, _) = makeHierarchy()
        var cycle = food
        cycle.parentID = restaurants.id   // Food under its own subcategory.

        await #expect(throws: CategoryHierarchyError.invalidParent) { try await basket.update(cycle) }
        // Nothing changed locally.
        #expect(basket.category(withID: food.id)?.parentID == nil)
    }

    @Test func updateRejectsMovingAParentUnderAnotherCategory() async {
        let (basket, food, _, transport) = makeHierarchy()
        var moved = food
        moved.parentID = transport.id   // Its subcategory Restaurants would become a 3rd level.

        await #expect(throws: CategoryHierarchyError.invalidParent) { try await basket.update(moved) }
    }

    @Test func createRejectsSubcategoryAsParent() async {
        let (basket, _, restaurants, _) = makeHierarchy()

        await #expect(throws: CategoryHierarchyError.invalidParent) {
            try await basket.create(CategoryDraft(name: "Sushi", parentID: restaurants.id))
        }
        #expect(!basket.categories.contains { $0.name == "Sushi" })
    }

    @Test func createRejectsUnknownParent() async {
        let (basket, _, _, _) = makeHierarchy()

        await #expect(throws: CategoryHierarchyError.invalidParent) {
            try await basket.create(CategoryDraft(name: "Orphan", parentID: 999))
        }
    }

    @Test func validHierarchyChangesAreSaved() async throws {
        let (basket, _, restaurants, transport) = makeHierarchy()

        var moved = restaurants
        moved.parentID = transport.id   // A subcategory moving to another root.
        try await basket.update(moved)
        try await basket.create(CategoryDraft(name: "Taxi", parentID: transport.id))

        #expect(basket.category(withID: restaurants.id)?.parentID == transport.id)
        #expect(basket.categories.contains { $0.name == "Taxi" && $0.parentID == transport.id })
    }

    @Test func legacyThirdLevelCategoryCanStillBeEdited() async throws {
        // Created before the rule: Food → Restaurants → Sushi.
        let (basket, _, restaurants, _) = makeHierarchy()
        let sushi = Category(id: 4, name: "Sushi", parentID: restaurants.id)
        let legacyBasket = CategoryBasket(
            categoryRepository: MockCategoryDataProvider(categories: basket.categories + [sushi]),
            categories: basket.categories + [sushi]
        )

        var renamed = sushi
        renamed.name = "Japanese"   // Same (non-root) parent: allowed.
        try await legacyBasket.update(renamed)

        #expect(legacyBasket.category(withID: sushi.id)?.name == "Japanese")
    }

    @Test func rootCategoryWalksUpToTopLevel() {
        let food = Category(id: 1, name: "Food")
        let restaurants = Category(id: 3, name: "Restaurants", parentID: food.id)
        let sushi = Category(id: 4, name: "Sushi", parentID: restaurants.id)
        let basket = CategoryBasket(categories: [food, restaurants, sushi])

        #expect(basket.rootCategory(of: sushi).id == food.id)
    }
}
