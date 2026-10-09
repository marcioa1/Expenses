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

    @Test func rootCategoryWalksUpToTopLevel() {
        let food = Category(id: 1, name: "Food")
        let restaurants = Category(id: 3, name: "Restaurants", parentID: food.id)
        let sushi = Category(id: 4, name: "Sushi", parentID: restaurants.id)
        let basket = CategoryBasket(categories: [food, restaurants, sushi])

        #expect(basket.rootCategory(of: sushi).id == food.id)
    }
}
