//
//  CategoryFormViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import Foundation
import SwiftData
import Observation

@Observable
class CategoryFormViewModel {
    var name: String = ""
    var icon: String = "folder"
    var isActive: Bool = true
    var parent: Category?

    let category: Category?

    var isEditing: Bool { category != nil }

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        if isDuplicateName { return "A category with this name already exists." }
        return nil
    }

    var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !isDuplicateName
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
        if let category {
            self.name = category.name
            self.icon = category.categoryIcon
            self.isActive = category.isActive
            self.parent = category.parent
        }
    }

    func validateName(in context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            isDuplicateName = false
            return
        }
        let predicate = #Predicate<Category> { $0.name == trimmed }
        let descriptor = FetchDescriptor(predicate: predicate)
        let existing = (try? context.fetch(descriptor)) ?? []
        // Allow keeping the same name when editing
        if let category, existing.count == 1, existing.first?.id == category.id {
            isDuplicateName = false
        } else {
            isDuplicateName = !existing.isEmpty
        }
    }

    func save(in context: ModelContext) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let category {
            category.name = trimmedName
            category.categoryIcon = icon
            category.isActive = isActive
            category.parent = parent
        } else {
            let newCategory = Category(name: trimmedName, isActive: isActive, categoryIcon: icon, parent: parent)
            context.insert(newCategory)
        }
    }
}
