//
//  ExpenseFormViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import SwiftData
import Observation

@Observable
class ExpenseFormViewModel {
    var selectedCategory: Category?
    var details: String = ""
    var value: Double?
    var datetime: Date = .now
    var categories: [Category] = []

    let expense: Expense?
    private var repository: (any DataProvider)?

    var isEditing: Bool { expense != nil }

    var canSave: Bool {
        selectedCategory != nil && value != nil && value! > 0
    }

    func configure(modelContext: ModelContext) async {
        repository = CategoryLocalDataProvider(modelContext: modelContext)
        await fetchCategories()
    }

    func configure(with repository: any DataProvider) async {
        self.repository = repository
        await fetchCategories()
    }

    func leafCategories() -> [Category] {
        categories.filter { $0.subcategories.isEmpty }
    }

    init(expense: Expense? = nil) {
        self.expense = expense
        if let expense {
            self.selectedCategory = expense.category
            self.details = expense.details ?? ""
            self.value = expense.value
            self.datetime = expense.datetime
        }
    }

    func save(in context: ModelContext) {
        guard let selectedCategory, let value else { return }
        let trimmedDetails = details.trimmingCharacters(in: .whitespaces)
        if let expense {
            expense.category = selectedCategory
            expense.details = trimmedDetails.isEmpty ? nil : trimmedDetails
            expense.value = value
            expense.datetime = datetime
        } else {
            let newExpense = Expense(
                category: selectedCategory,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails,
                value: value,
                datetime: datetime
            )
            context.insert(newExpense)
        }
    }

    private func fetchCategories() async {
        guard let repository else { return }
        let fetched = (try? await repository.fetchAll() as? [Category]) ?? []
        categories = fetched.sorted { $0.name < $1.name }
    }
}
