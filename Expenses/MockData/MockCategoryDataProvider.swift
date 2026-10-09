//
//  MockCategoryDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 12/08/26.
//

#if DEBUG
import Foundation

@MainActor
final class MockCategoryDataProvider: CategoryRepository {
    typealias Item = Category

    private var categories: [Category]

    init() {
        self.categories = [
            Category(name: "Food", categoryIcon: "fork.knife"),
            Category(name: "Transport", categoryIcon: "car.fill"),
            Category(name: "Entertainment", categoryIcon: "gamecontroller.fill"),
            Category(name: "Health", categoryIcon: "heart.fill"),
            Category(name: "Shopping", categoryIcon: "bag.fill")
        ]
    }

    init(categories: [Category]) {
        self.categories = categories
    }

    func fetchAll() async throws -> [Category] {
        categories
    }

    func create(_ category: Category) async throws -> Category {
        categories.append(category)
        return category
    }

    func update(_ category: Category) async throws -> Category {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
        return category
    }

    func delete(_ category: Category) async throws {
        categories.removeAll { $0.id == category.id }
    }
}
#endif
