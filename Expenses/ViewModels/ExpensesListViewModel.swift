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
    var  categories: [Category]?
    private var categoryRepository: (any DataProvider)?

    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set { monthFilter.selectedMonthIndex = newValue }
    }

    func filteredExpenses(from allExpenses: [Expense]) -> [Expense] {
        var result = monthFilter.filteredExpenses(from: allExpenses)
        if let selectedCategory {
            result = result.filter { $0.category.id == selectedCategory.id || $0.category.parent?.id == selectedCategory.id }
        }
        return result
    }
    
    func totalAmount(from allExpenses: [Expense]) -> Double {
        filteredExpenses(from: allExpenses).reduce(0) { $0 + $1.value }
    }
    
    func deleteExpenses(at offsets: IndexSet, from expenses: [Expense], in context: ModelContext) {
        for index in offsets {
            context.delete(expenses[index])
        }
    }
    
    func configure(modelContext: ModelContext) async {
        categoryRepository = CategoryLocalDataProvider(modelContext: modelContext)
        await getAllCategories()
    }
    private func getAllCategories() async {
        guard let categoryRepository else { return }
        categories = (try? await categoryRepository.fetchAll() as? [Category]) ?? []
    }
}
