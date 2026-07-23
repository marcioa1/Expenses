//
//  SummaryViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation

@Observable
class SummaryViewModel: MonthFilterable {
    var expenseToEdit: Expense?
    let monthFilter = MonthFilter()

    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set { monthFilter.selectedMonthIndex = newValue }
    }

    func rootCategory(of category: Category) -> Category {
        var current = category
        while let parent = current.parent {
            current = parent
        }
        return current
    }

    func expensesByParent(from allExpenses: [Expense], categories: [Category]) -> [(parent: Category, subtotals: [(category: Category, total: Double)], total: Double)] {
        let filtered = monthFilter.filteredExpenses(from: allExpenses)
        var parentMap: [UUID: (parent: Category, children: [UUID: Double])] = [:]

        for expense in filtered {
            let root = rootCategory(of: expense.category)
            if parentMap[root.id] == nil {
                parentMap[root.id] = (parent: root, children: [:])
            }
            parentMap[root.id]!.children[expense.category.id, default: 0] += expense.value
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
}
