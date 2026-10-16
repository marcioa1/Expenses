//
//  SummaryViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation

@MainActor
@Observable
class SummaryViewModel: MonthFilterable {
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
    var loadingState: LoadingState = .loading

    func category(for expense: Expense) -> Category? {
        categoryBasket?.category(withID: expense.categoryID)
    }

    init(previewState: LoadingState = .loading) {
        loadingState = previewState
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.categoryBasket = categoryBasket
        self.expenseBasket = expenseBasket
        // Both loads run in parallel; the screen only succeeds if both do,
        // so one load finishing later can't overwrite the other's failure.
        async let categoriesLoaded = loadCategories()
        async let expensesLoaded = loadExpenses()
        let succeeded = await (categoriesLoaded, expensesLoaded) == (true, true)
        loadingState = succeeded ? .success : .failed
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

    /// - Returns: `true` if expenses are available.
    private func loadExpenses() async -> Bool {
        guard let expenseBasket else { return false }
        do {
            // The basket is shared by every tab and months are filtered in memory,
            // so only the first call actually hits the server.
            try await expenseBasket.loadIfNeeded()
            return true
        } catch {
            return false
        }
    }

    /// - Returns: `true` if categories are available.
    private func loadCategories() async -> Bool {
        guard let categoryBasket else { return false }
        do {
            try await categoryBasket.loadIfNeeded()
            return true
        } catch {
            return false
        }
    }

}
