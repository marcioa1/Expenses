//
//  ExpenseFilter.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

import Foundation

/// Category and "extra" filters chosen in `FilterView`, shared by the Expenses, Grid and Chart tabs.
struct ExpenseFilter: Equatable {
    var category: Category?
    var extra: ExtraOption = .all

    /// Whether any filter differs from its default, so the toolbar can highlight the filter button.
    var isActive: Bool {
        category != nil || extra != .all
    }

    /// Keeps the expenses matching both filters. A category also matches its subcategories,
    /// which is why `categories` is needed.
    func apply(to expenses: [Expense], categories: [Category]) -> [Expense] {
        let categoryIDs = category.map { categories.ids(matching: $0) }
        return expenses.filter { expense in
            if let categoryIDs, !categoryIDs.contains(expense.categoryID) {
                return false
            }
            switch extra {
            case .all:
                return true
            case .extra:
                return expense.extraordinary
            case .regular:
                return !expense.extraordinary
            }
        }
    }
}
