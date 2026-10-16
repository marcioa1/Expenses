//
//  CategoryFormViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import Foundation
import Observation

@MainActor
@Observable
class CategoryFormViewModel {
    var name: String = ""
    var icon: String = "folder"
    var isActive: Bool = true
    var parent: Category?
    var isSaving = false
    var errorMessage: String?

    let category: Category?
    /// Shared category store, provided by the view via `configure`.
    private var categoryBasket: CategoryBasket?

    /// All categories currently loaded; used for parent selection, subcategories and name validation.
    var categories: [Category] {
        categoryBasket?.categories ?? []
    }

    var isEditing: Bool { category != nil }

    /// Categories go at most two levels deep (a root and its direct subcategories), which is
    /// what the category grid and the filters (`ids(matching:)`) are built for.
    /// A category that has subcategories must stay a root, or its children would become a third level.
    var canHaveParent: Bool {
        subcategories.isEmpty
    }

    /// Root categories other than this one. Only roots can be parents, so a category can never
    /// be moved under one of its own descendants (which would hide both from the grid).
    var availableParents: [Category] {
        var parents = canHaveParent
            ? categories.filter { $0.parentID == nil && $0.id != category?.id }
            : []
        // Data created before the two-level rule may have a non-root parent; keep it listed
        // while editing so the picker's current selection stays valid.
        if let originalParent = categories.category(withID: category?.parentID),
           !parents.contains(originalParent) {
            parents.append(originalParent)
        }
        return parents
    }

    var subcategories: [Category] {
        guard let category else { return [] }
        return categories.subcategories(of: category)
    }

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        if isDuplicateName { return String(localized: "A category with this name already exists.") }
        return nil
    }

    var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !isDuplicateName && !isSaving
    }

    private var isDuplicateName: Bool = false

    let iconOptions = [
        // General
        "folder", "star.fill", "tag.fill", "bookmark.fill",
        // Food & Drink
        "fork.knife", "cup.and.saucer.fill", "cart.fill", "basket.fill",
        // Transport
        "car.fill", "bus.fill", "bicycle", "airplane", "fuelpump.fill",
        // Home & Utilities
        "house.fill", "lightbulb.fill", "bolt.fill", "drop.fill", "flame.fill",
        // Health & Fitness
        "heart.fill", "cross.case.fill", "figure.run", "dumbbell.fill",
        // Entertainment
        "gamecontroller.fill", "music.note", "film.fill", "tv.fill", "theatermasks.fill",
        // Shopping & Fashion
        "bag.fill", "tshirt.fill", "gift.fill", "creditcard.fill",
        // Education & Work
        "book.fill", "graduationcap.fill", "briefcase.fill", "laptopcomputer",
        // Communication
        "phone.fill", "envelope.fill", "bubble.left.fill", "wifi",
        // Finance
        "dollarsign.circle.fill", "banknote.fill", "chart.line.uptrend.xyaxis",
        // Pets & Nature
        "pawprint.fill", "leaf.fill", "tree.fill",
        // Tools & Other
        "wrench.and.screwdriver.fill", "scissors", "paintbrush.fill", "camera.fill"
    ]

    init(category: Category? = nil) {
        self.category = category
        // `parent` is resolved from `category.parentID` once categories are fetched.
        if let category {
            self.name = category.name
            self.icon = category.icon
            self.isActive = category.isActive
        }
    }

    func configure(with categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        try? await categoryBasket.loadIfNeeded()
        if let category {
            parent = categoryBasket.category(withID: category.parentID)
        }
    }

    func validateName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            isDuplicateName = false
            return
        }
        // Allow keeping the same name when editing
        isDuplicateName = categories.contains { $0.name == trimmed && $0.id != category?.id }
    }

    /// Creates or updates the category on the server; the shared basket is updated on success.
    /// - Returns: `true` on success; on failure `errorMessage` is set.
    func save() async -> Bool {
        guard let categoryBasket else { return false }
        isSaving = true
        defer { isSaving = false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        do {
            if var item = category {
                item.name = trimmedName
                item.icon = icon
                item.isActive = isActive
                item.parentID = parent?.id
                try await categoryBasket.update(item)
            } else {
                // New categories have no `id` yet; the server assigns it.
                try await categoryBasket.create(CategoryDraft(
                    name: trimmedName,
                    isActive: isActive,
                    icon: icon,
                    parentID: parent?.id
                ))
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
