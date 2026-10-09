//
//  CategoryBasket.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/09/26.
//

import Foundation
import Observation

/// App-wide store of categories, shared by every screen through the SwiftUI environment.
///
/// Categories are fetched once (`loadIfNeeded()`) and kept in memory; writes go through
/// the repository and update `categories` in place so every tab sees the change.
@MainActor
@Observable
final class CategoryBasket {
    private let categoryRepository: (any CategoryRepository)?
    private(set) var categories: [Category]
    private(set) var hasLoaded = false
    /// In-flight fetch, so tabs appearing at the same time share a single request.
    @ObservationIgnored private var loadTask: Task<Void, Error>?

    /// - Parameter categories: Initial categories; handy for previews and tests that don't need a repository.
    init(categoryRepository: (any CategoryRepository)? = nil, categories: [Category] = []) {
        self.categoryRepository = categoryRepository
        self.categories = categories
    }

    // MARK: - Loading

    /// Fetches categories only if they haven't been loaded yet.
    func loadIfNeeded() async throws {
        guard !hasLoaded else { return }
        if let loadTask {
            return try await loadTask.value
        }
        let task = Task { try await getAllCategories() }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    /// Always fetches categories from the repository (e.g. pull-to-refresh).
    func getAllCategories() async throws {
        guard let categoryRepository else { return }
        categories = try await categoryRepository.fetchAll()
        hasLoaded = true
    }

    // MARK: - Writes

    func create(_ category: Category) async throws {
        guard let categoryRepository else { return }
        let created = try await categoryRepository.create(category)
        categories.append(created)
        sortCategories()
    }

    func update(_ category: Category) async throws {
        guard let categoryRepository else { return }
        let updated = try await categoryRepository.update(category)
        if let index = categories.firstIndex(where: { $0.id == updated.id }) {
            categories[index] = updated
        }
        sortCategories()
    }

    func delete(_ category: Category) async throws {
        guard let categoryRepository else { return }
        try await categoryRepository.delete(category)
        categories.removeAll { $0.id == category.id }
    }

    // MARK: - Lookups

    func category(withID id: UUID?) -> Category? {
        categories.category(withID: id)
    }

    func rootCategory(of category: Category) -> Category {
        categories.root(of: category)
    }

    private func sortCategories() {
        categories.sort { $0.name < $1.name }
    }
}
