//
//  SummaryViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation

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
        monthFilter.totalAmount(from: filteredExpenses)
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

    func expensesByParent() -> [(parent: Category, subtotals: [(category: Category, total: Decimal)], total: Decimal)] {
        guard let categoryBasket else { return [] }
        let filtered = monthFilter.filteredExpenses(from: self.expenses)
        var parentMap: [Int: (parent: Category, children: [Int: Decimal])] = [:]

        for expense in filtered {
            // Expenses whose category is not (or no longer) on the server are left out of the breakdown.
            guard let category = categoryBasket.category(withID: expense.categoryID) else { continue }
            let root = categoryBasket.rootCategory(of: category)
            if parentMap[root.id] == nil {
                parentMap[root.id] = (parent: root, children: [:])
            }
            parentMap[root.id]!.children[category.id, default: 0] += expense.value
        }

        return parentMap.values
            .map { entry in
                let subtotals = entry.children.compactMap { (catId, total) -> (category: Category, total: Decimal)? in
                    guard let cat = categories.first(where: { $0.id == catId }) else { return nil }
                    return (category: cat, total: total)
                }
                .sorted { $0.total > $1.total }

                let total = subtotals.reduce(0) { $0 + $1.total }
                return (parent: entry.parent, subtotals: subtotals, total: total)
            }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }
}
