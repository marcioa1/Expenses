//
//  Category.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import Foundation

/// A category as exchanged with the backend (`api/categories`).
///
/// The server sends a flat list where each item points to its parent through
/// `parent_id`; the hierarchy is rebuilt on the client with the helpers in the
/// `Array<Category>` extension below. IDs are assigned by the server.
/// `nonisolated` opts this value type out of the target's default `MainActor` isolation.
nonisolated struct Category: Identifiable, Hashable, Codable {
    var id: Int
    var name: String
    var isActive: Bool
    var icon: String
    var parentID: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isActive = "is_active"
        case icon
        case parentID = "parent_id"
    }

    init(id: Int, name: String, isActive: Bool = true, icon: String = "folder", parentID: Int? = nil) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.icon = icon
        self.parentID = parentID
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(icon, forKey: .icon)
        // Always send `parent_id` (as `null` when absent) so an update can clear the parent.
        try container.encode(parentID, forKey: .parentID)
    }
}

/// Body for creating a category; it has no `id` because the server assigns it.
struct CategoryDraft: Encodable, Equatable {
    var name: String
    var isActive: Bool = true
    var icon: String = "folder"
    var parentID: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case isActive = "is_active"
        case icon
        case parentID = "parent_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(icon, forKey: .icon)
        try container.encode(parentID, forKey: .parentID)
    }
}

// MARK: - Hierarchy helpers

extension Array where Element == Category {
    func category(withID id: Int?) -> Category? {
        guard let id else { return nil }
        return first { $0.id == id }
    }

    /// Direct children of `category`, sorted by name.
    func subcategories(of category: Category) -> [Category] {
        filter { $0.parentID == category.id }.sorted { $0.name < $1.name }
    }

    /// Top-most ancestor of `category` (the category itself when it has no parent).
    func root(of category: Category) -> Category {
        var current = category
        var visited: Set<Int> = [category.id]
        // `visited` guards against a malformed cycle coming from the server.
        while let parent = self.category(withID: current.parentID), visited.insert(parent.id).inserted {
            current = parent
        }
        return current
    }

    /// IDs of `category` and its direct subcategories; used by the category filters.
    func ids(matching category: Category) -> Set<Int> {
        Set([category.id] + subcategories(of: category).map(\.id))
    }
}

// MARK: - Two-level rule

/// Categories go at most two levels deep: a root and its direct subcategories. The category grid
/// and the filters (`ids(matching:)`) are built for exactly that, and the rule also makes cycles
/// (a category under its own descendant, which hides both from the grid) impossible.
extension Array where Element == Category {
    /// Whether `category` may be placed under another one: a category that has subcategories must
    /// stay a root, or its children would become a third level. A new category (`nil`) always can.
    func canHaveParent(_ category: Category?) -> Bool {
        guard let category else { return true }
        return subcategories(of: category).isEmpty
    }

    /// The categories `category` (`nil` for a new one) may be placed under: root categories other
    /// than itself, or none if it has subcategories.
    ///
    /// Data created before the rule may already have a non-root parent; it's kept in the list so
    /// a form editing that category still shows its current selection.
    func allowedParents(for category: Category?) -> [Category] {
        var parents = canHaveParent(category)
            ? filter { $0.parentID == nil && $0.id != category?.id }
            : []
        if let currentParent = self.category(withID: category?.parentID), !parents.contains(currentParent) {
            parents.append(currentParent)
        }
        return parents
    }

    /// Checks that giving `parentID` to the category with `categoryID` (`nil` when creating one)
    /// keeps the two-level rule. Keeping a category's current parent is always allowed, so
    /// pre-existing deeper data can still be edited.
    func validateParent(_ parentID: Int?, forCategoryWithID categoryID: Int?) throws {
        guard let parentID else { return }   // Becoming (or staying) a root is always fine.
        let existing = self.category(withID: categoryID)
        if let existing, existing.parentID == parentID { return }

        guard let parent = self.category(withID: parentID),
              parent.parentID == nil,
              parent.id != categoryID,
              canHaveParent(existing)
        else {
            throw CategoryHierarchyError.invalidParent
        }
    }
}

enum CategoryHierarchyError: LocalizedError, Equatable {
    /// The parent would create a third level or a cycle (see `validateParent`).
    case invalidParent

    var errorDescription: String? {
        switch self {
        case .invalidParent:
            String(localized: "A category can only be placed under a main category, and only if it has no subcategories itself.")
        }
    }
}
