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
    /// Whether categories are available, shared by every screen that shows them.
    ///
    /// Only the **first** load can fail the state: once categories are loaded, a failed refresh
    /// keeps them (and `.success`) and just throws, so screens keep their data and show a message.
    private(set) var loadState: LoadingState = .loading
    /// In-flight fetch, so tabs appearing at the same time share a single request.
    @ObservationIgnored private var loadTask: Task<Void, Error>?

    /// - Parameter categories: Initial categories; handy for previews and tests that don't need a repository.
    init(categoryRepository: (any CategoryRepository)? = nil, categories: [Category] = []) {
        self.categoryRepository = categoryRepository
        self.categories = categories
    }

    // MARK: - Loading

    /// Fetches categories only if they haven't been loaded yet; after a failure, the next call retries.
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
        // Without a repository (previews, tests) the initial categories are all there is.
        guard let categoryRepository else {
            hasLoaded = true
            loadState = .success
            return
        }
        // A retry after a failed first load shows the spinner again; a refresh keeps the data on screen.
        if !hasLoaded { loadState = .loading }
        do {
            let fetched = try await categoryRepository.fetchAll()
            // Cancelled by `reset()` (logout): don't hand the previous user's data to the next one.
            try Task.checkCancellation()
            categories = fetched
            hasLoaded = true
            loadState = .success
        } catch {
            // A cancelled load isn't a failure; `reset()` already put the state back to `.loading`.
            if !hasLoaded && !Task.isCancelled { loadState = .failed }
            throw error
        }
    }

    /// Drops all loaded categories (e.g. on logout) so the next user starts with a fresh fetch.
    func reset() {
        loadTask?.cancel()
        loadTask = nil
        categories = []
        hasLoaded = false
        loadState = .loading
    }

    // MARK: - Writes

    /// - Throws: `CategoryHierarchyError.invalidParent` (without contacting the server) if the
    ///   parent would break the two-level rule.
    func create(_ draft: CategoryDraft) async throws {
        try categories.validateParent(draft.parentID, forCategoryWithID: nil)
        guard let categoryRepository else { return }
        let created = try await categoryRepository.create(draft)
        categories.append(created)
        sortCategories()
    }

    /// - Throws: `CategoryHierarchyError.invalidParent` (without contacting the server) if the
    ///   new parent would break the two-level rule.
    func update(_ category: Category) async throws {
        try categories.validateParent(category.parentID, forCategoryWithID: category.id)
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

    func category(withID id: Int?) -> Category? {
        categories.category(withID: id)
    }

    func rootCategory(of category: Category) -> Category {
        categories.root(of: category)
    }

    private func sortCategories() {
        categories.sort { $0.name < $1.name }
    }
}
