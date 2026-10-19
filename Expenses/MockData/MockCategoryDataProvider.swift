//
//  MockCategoryDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 12/08/26.
//

#if DEBUG
import Foundation

@MainActor
final class MockCategoryDataProvider: @MainActor CategoryRepository {
    typealias Item = Category

    private var categories: [Category]
    /// When set, every fetch throws this error (e.g. to preview the error screen). It can be changed
    /// between calls, e.g. set after a first successful load to simulate a failed refresh.
    var fetchError: Error?
    /// The next `failingFetches` fetches throw `MockRepositoryError.fetchFailed`, then fetches succeed
    /// again: a failed first load followed by a successful retry.
    var failingFetches: Int
    /// When set, `create`, `update` and `delete` throw this error (e.g. a network error on save).
    var writeError: Error?

    /// Sample categories, for previews.
    static let sampleCategories = [
        Category(id: 1, name: "Food", icon: "fork.knife"),
        Category(id: 2, name: "Transport", icon: "car.fill"),
        Category(id: 3, name: "Entertainment", icon: "gamecontroller.fill"),
        Category(id: 4, name: "Health", icon: "heart.fill"),
        Category(id: 5, name: "Shopping", icon: "bag.fill")
    ]

    init(
        categories: [Category] = MockCategoryDataProvider.sampleCategories,
        fetchError: Error? = nil,
        failingFetches: Int = 0,
        writeError: Error? = nil
    ) {
        self.categories = categories
        self.fetchError = fetchError
        self.failingFetches = failingFetches
        self.writeError = writeError
    }

    func fetchAll() async throws -> [Category] {
        if failingFetches > 0 {
            failingFetches -= 1
            throw MockRepositoryError.fetchFailed
        }
        if let fetchError { throw fetchError }
        return categories
    }

    /// Mimics the server by assigning the next available `id`.
    func create(_ draft: CategoryDraft) async throws -> Category {
        if let writeError { throw writeError }
        let nextID = (categories.map(\.id).max() ?? 0) + 1
        let category = Category(
            id: nextID,
            name: draft.name,
            isActive: draft.isActive,
            icon: draft.icon,
            parentID: draft.parentID
        )
        categories.append(category)
        return category
    }

    func update(_ category: Category) async throws -> Category {
        if let writeError { throw writeError }
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
        return category
    }

    func delete(_ category: Category) async throws {
        if let writeError { throw writeError }
        categories.removeAll { $0.id == category.id }
    }
}
#endif
