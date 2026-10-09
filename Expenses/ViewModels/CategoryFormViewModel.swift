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
    /// All categories currently loaded; used for parent selection, subcategories and name validation.
    let categories: [Category]
    private let repository: any CategoryRepository

    var isEditing: Bool { category != nil }

    var availableParents: [Category] {
        categories.filter { $0.id != category?.id }
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

    init(category: Category? = nil, categories: [Category], repository: any CategoryRepository) {
        self.category = category
        self.categories = categories
        self.repository = repository
        if let category {
            self.name = category.name
            self.icon = category.categoryIcon
            self.isActive = category.isActive
            self.parent = categories.category(withID: category.parentID)
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

    /// Creates or updates the category on the server.
    /// - Returns: `true` on success; on failure `errorMessage` is set.
    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }

        var item = category ?? Category(name: "")
        item.name = name.trimmingCharacters(in: .whitespaces)
        item.categoryIcon = icon
        item.isActive = isActive
        item.parentID = parent?.id

        do {
            if isEditing {
                _ = try await repository.update(item)
            } else {
                _ = try await repository.create(item)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
