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
            Category(id: 1, name: "Food", categoryIcon: "fork.knife"),
            Category(id: 2, name: "Transport", categoryIcon: "car.fill"),
            Category(id: 3, name: "Entertainment", categoryIcon: "gamecontroller.fill"),
            Category(id: 4, name: "Health", categoryIcon: "heart.fill"),
            Category(id: 5, name: "Shopping", categoryIcon: "bag.fill")
        ]
    }

    init(categories: [Category]) {
        self.categories = categories
    }

    func fetchAll() async throws -> [Category] {
        categories
    }

    /// Mimics the server by assigning the next available `id`.
    func create(_ draft: CategoryDraft) async throws -> Category {
        let nextID = (categories.map(\.id).max() ?? 0) + 1
        let category = Category(
            id: nextID,
            name: draft.name,
            isActive: draft.isActive,
            categoryIcon: draft.categoryIcon,
            parentID: draft.parentID
        )
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
