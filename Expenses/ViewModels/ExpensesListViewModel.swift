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
    let monthFilter = MonthFilter()
    
    var categories: [Category]?
    var expenses: [Expense] = []
    private var categoryRepository: (any DataProvider)?
    private var expenseRepository: ExpenseLocalDataProvider?
    
    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set {
            monthFilter.selectedMonthIndex = newValue
            Task { await self.refreshExpenses() }
        }
    }
    
    func filteredExpenses() -> [Expense] {
        guard let selectedCategory else { return expenses }
        return expenses.filter { $0.category.id == selectedCategory.id || $0.category.parent?.id == selectedCategory.id }
    }
    
    var totalAmount: Double {
        filteredExpenses(from: self.expenses).reduce(0) { $0 + $1.value }
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
    }
    
    private func getAllCategories() async {
        guard let categoryRepository else { return }
        categories = (try? await categoryRepository.fetchAll() as? [Category]) ?? []
    }
    
    private func refreshExpenses() async {
        guard let expenseRepository else { return }
        let start = monthFilter.monthStart()
        let end = monthFilter.monthEnd()
        expenses = (try? await expenseRepository.fetch(from: start, to: end)) ?? []
    }

}
