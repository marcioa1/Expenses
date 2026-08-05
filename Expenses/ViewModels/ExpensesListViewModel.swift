//
//  ExpensesListViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import SwiftData
import Observation

@Observable
class ExpensesListViewModel: MonthFilterable {
    var showingForm = false
    var expenseToEdit: Expense?
    var selectedCategory: Category?
    var selectedSort: SortOption = .date
    let monthFilter = MonthFilter()
    var loadingState: LoadingState = .loading
    
    var categories: [Category]?
    var expenses: [Expense] = []
    private var categoryRepository: (any DataProvider)?
    private var expenseRepository: ExpenseLocalDataProvider?
    
    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set {
            monthFilter.selectedMonthIndex = newValue
            loadingState = .loading
            Task { await self.refreshExpenses() }
        }
    }
    
    func filteredExpenses() -> [Expense] {
        var result = expenses
        if let selectedCategory {
            result = result.filter { $0.category.id == selectedCategory.id || $0.category.parent?.id == selectedCategory.id }
        }
        switch selectedSort {
        case .date:
            return result.sorted { $0.datetime > $1.datetime }
        case .value:
            return result.sorted { $0.value > $1.value }
        }
    }
    
    var totalAmount: Double {
        filteredExpenses().reduce(0) { $0 + $1.value }
    }
    
    func deleteExpenses(at offsets: IndexSet, from expenses: [Expense], in context: ModelContext) {
        for index in offsets {
            context.delete(expenses[index])
        }
    }
    
    func configure(modelContext: ModelContext) async {
        categoryRepository = CategoryLocalDataProvider(modelContext: modelContext)
        expenseRepository = ExpenseLocalDataProvider(modelContext: modelContext)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getAllCategories() }
            group.addTask { await self.refreshExpenses() }
        }
        if loadingState != .failed {
            loadingState = .success
        }
    }
    
    private func getAllCategories() async {
        guard let categoryRepository else { return }
        do {
            categories = try await categoryRepository.fetchAll() as? [Category]
        } catch {
            loadingState = .failed
        }
    }
    
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
