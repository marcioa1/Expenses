//
//  SummaryViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation

/// How much was spent in one category.
struct CategoryTotal: Identifiable {
    let category: Category
    let total: Decimal

    var id: Int { category.id }
}

/// One row of the Summary breakdown: a root category and what was spent in it and its subcategories.
struct CategoryGroup: Identifiable {
    let parent: Category
    /// Largest first. Expenses logged directly on the parent appear here as a subtotal for the parent itself.
    let subtotals: [CategoryTotal]

    var id: Int { parent.id }

    var total: Decimal {
        subtotals.reduce(0) { $0 + $1.total }
    }

    /// Whether a real subcategory has expenses, i.e. whether the row is worth expanding.
    var hasChildren: Bool {
        subtotals.contains { $0.category.id != parent.id }
    }
}

@Observable
final class SummaryViewModel: MonthFilterable {
    /// Shared stores, provided by the view via `configure`.
    private var baskets: SharedBaskets?
    private var categoryBasket: CategoryBasket? { baskets?.categoryBasket }
    private var expenseBasket: ExpenseBasket? { baskets?.expenseBasket }

    var expenseToEdit: Expense?
    let monthFilter = MonthFilter()
    
    var categories: [Category] {
        categoryBasket?.categories ?? []
    }
    var expenses: [Expense] {
        expenseBasket?.expenses ?? []
    }
    
    var totalAmount: Decimal {
        filteredExpenses.reduce(0) { $0 + $1.value }
    }

    var filteredExpenses: [Expense] {
        monthFilter.filteredExpenses(from: expenses)
    }
    
    var loadingState: LoadingState {
        baskets?.loadingState ?? .loading
    }

    func category(for expense: Expense) -> Category? {
        categoryBasket?.category(withID: expense.categoryID)
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        let baskets = SharedBaskets(categoryBasket: categoryBasket, expenseBasket: expenseBasket)
        self.baskets = baskets
        // Months are filtered in memory, so changing month never needs another fetch.
        await baskets.loadIfNeeded()
    }

    /// The month's spending per root category, largest first, each with its subcategory totals.
    var categoryGroups: [CategoryGroup] {
        guard let categoryBasket else { return [] }
        var parentMap: [Int: (parent: Category, children: [Int: Decimal])] = [:]

        for expense in filteredExpenses {
            // Expenses whose category is not (or no longer) on the server are left out of the breakdown.
            guard let category = categoryBasket.category(withID: expense.categoryID) else { continue }
            let root = categoryBasket.rootCategory(of: category)
            parentMap[root.id, default: (parent: root, children: [:])].children[category.id, default: 0] += expense.value
        }

        return parentMap.values
            .map { entry in
                let subtotals = entry.children
                    .compactMap { categoryID, total in
                        categoryBasket.category(withID: categoryID).map { CategoryTotal(category: $0, total: total) }
                    }
                    .sorted { $0.total > $1.total }
                return CategoryGroup(parent: entry.parent, subtotals: subtotals)
            }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }
}
