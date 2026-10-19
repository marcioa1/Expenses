//
//  SummaryViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation

@Observable
final class SummaryViewModel: MonthFilterable {
    private var categoryBasket: CategoryBasket?
    private var expenseBasket: ExpenseBasket?

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
    
    /// Derived from the shared baskets, so every tab agrees on whether the data is available.
    var loadingState: LoadingState {
        guard let categoryBasket, let expenseBasket else { return .loading }
        return .combined(categoryBasket.loadState, expenseBasket.loadState)
    }

    func category(for expense: Expense) -> Category? {
        categoryBasket?.category(withID: expense.categoryID)
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.categoryBasket = categoryBasket
        self.expenseBasket = expenseBasket
        // The baskets are shared by every tab and months are filtered in memory, so only the
        // first call actually hits the server. Errors are reflected in each basket's `loadState`.
        async let categories: Void? = try? categoryBasket.loadIfNeeded()
        async let expenses: Void? = try? expenseBasket.loadIfNeeded()
        _ = await (categories, expenses)
    }

    /// Months are filtered in memory from the shared basket, so changing month needs no fetch.
    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set { monthFilter.selectedMonthIndex = newValue }
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
