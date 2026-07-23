//
//  Category.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    @Attribute(.unique) var name: String
    var isActive: Bool
    var categoryIcon: String
    var parent: Category?
    @Relationship(deleteRule: .cascade, inverse: \Category.parent)
    var subcategories: [Category] = []
    @Relationship(deleteRule: .deny, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(id: UUID = UUID(), name: String, isActive: Bool = true, categoryIcon: String = "folder", parent: Category? = nil) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.categoryIcon = categoryIcon
        self.parent = parent
    }
}
