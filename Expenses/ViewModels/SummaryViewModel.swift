//
//  SummaryViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation
import SwiftData

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
        categoryBasket?.category(withID: expense.remoteCategoryID)
    }

    init(previewState: LoadingState = .loading) {
        loadingState = previewState
    }

    func configure(modelContext: ModelContext, categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        expenseBasket = ExpenseBasket(expenseRepository: ExpenseLocalDataProvider(modelContext: modelContext))
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshCategories() }
            group.addTask { await self.refreshExpenses() }
        }
        if loadingState != .failed {
            loadingState = .success
        }
    }

    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set {
            monthFilter.selectedMonthIndex = newValue
            loadingState = .loading
            Task { await self.refreshExpenses() }
        }
    }

    func expensesByParent() -> [(parent: Category, subtotals: [(category: Category, total: Double)], total: Double)] {
        guard let categoryBasket else { return [] }
        let filtered = monthFilter.filteredExpenses(from: self.expenses)
        var parentMap: [Int: (parent: Category, children: [Int: Double])] = [:]

        for expense in filtered {
            // Expenses whose category is not (or no longer) on the server are left out of the breakdown.
            guard let category = categoryBasket.category(withID: expense.remoteCategoryID) else { continue }
            let root = categoryBasket.rootCategory(of: category)
            if parentMap[root.id] == nil {
                parentMap[root.id] = (parent: root, children: [:])
            }
            parentMap[root.id]!.children[category.id, default: 0] += expense.value
        }

        return parentMap.values
            .map { entry in
                let subtotals = entry.children.compactMap { (catId, total) -> (category: Category, total: Double)? in
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

    private func refreshExpenses() async {
        guard let expenseBasket else { return }
        do {
            try await expenseBasket.getAllExpenses()
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }
    
    private func refreshCategories() async {
        guard let categoryBasket else { return }
        do {
            try await categoryBasket.loadIfNeeded()
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }
    
}
