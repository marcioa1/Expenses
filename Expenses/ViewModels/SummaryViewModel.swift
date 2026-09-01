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
    private var categoryRepository: (any DataProvider)?
    private var categoryBasket: CategoryBasket?
    private var expenseRepository: ExpenseLocalDataProvider?
    
    var expenseToEdit: Expense?
    let monthFilter = MonthFilter()
    var categories: [Category] {
        self.categoryBasket?.categories ?? []
    }
    var expenses: [Expense] = []
    var loadingState: LoadingState = .loading
    
    init(previewState: LoadingState = .loading) {
        loadingState = previewState
    }

    func configure(modelContext: ModelContext) async {
        categoryRepository = CategoryLocalDataProvider(modelContext: modelContext)
        categoryBasket = CategoryBasket(categoryRepository: categoryRepository)
        expenseRepository = ExpenseLocalDataProvider(modelContext: modelContext)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.categoryBasket?.getAllCategories()
                } catch {
                    await MainActor.run { self.loadingState = .failed }
                }
            }
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
            Task { await self.refreshExpenses()
            }
        }
    }
    
//    func rootCategory(of category: Category) -> Category {
//        var current = category
//        while let parent = current.parent {
//            current = parent
//        }
//        return current
//    }
    
    func expensesByParent() -> [(parent: Category, subtotals: [(category: Category, total: Double)], total: Double)] {
        guard let categoryBasket else { return [] }
        let filtered = monthFilter.filteredExpenses(from: self.expenses)
        var parentMap: [UUID: (parent: Category, children: [UUID: Double])] = [:]
        
        for expense in filtered {
            let root = categoryBasket.rootCategory(of: expense.category)
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
    
//    private func getAllCategories() async {
//        guard let categoryRepository else { return }
//        do {
//            categories = try await categoryRepository.fetchAll() as! [Category]
//        } catch {
//            loadingState = .failed
//        }
//    }
    
    func refreshExpenses() async {
        try? await Task.sleep(for: .seconds(1))
        guard let expenseRepository else { return }
        let start = monthFilter.monthStart()
        let end = monthFilter.monthEnd()
        do {
            expenses = try await expenseRepository.fetch(from: start, to: end)
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }
}
