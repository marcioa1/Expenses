//
//  ExpensesListViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation

@MainActor
@Observable
class ExpensesListViewModel: MonthFilterable {
    var showingForm = false
    var expenseToEdit: Expense?
    var selectedCategory: Category?
    var selectedSort: SortOption? = .date
    var selectedExtra: ExtraOption = .all
    let monthFilter = MonthFilter()
    var loadingState: LoadingState = .loading
    /// Message of the last failed write (delete / update), shown as an alert by the view.
    var errorMessage: String?

    /// Shared category store, provided by the view via `configure`.
    var categoryBasket: CategoryBasket?
    var categories: [Category] {
        categoryBasket?.categories ?? []
    }
    /// Shared expense store, provided by the view via `configure`.
    var expenseBasket: ExpenseBasket?
    /// Expenses of the selected month, newest first.
    var expenses: [Expense] {
        expenseBasket?.expenses(from: monthFilter.monthStart(), to: monthFilter.monthEnd()) ?? []
    }

    /// Months are filtered in memory from the shared basket, so changing month needs no fetch.
    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set { monthFilter.selectedMonthIndex = newValue }
    }
    
    func filteredExpenses() -> [Expense] {
        var result = expenses
        if let selectedCategory {
            let ids = categories.ids(matching: selectedCategory)
            result = result.filter { ids.contains($0.categoryID) }
        }
        
        switch selectedSort {
        case .date:
            result = result.sorted { $0.datetime > $1.datetime }
        case .value:
            result = result.sorted { $0.value > $1.value }
        case .none:
            break
        }
        
        switch selectedExtra {
        case .all:
            break
        case .extra:
            result = result.filter { $0.extraordinary }
        case .regular:
            result = result.filter { !$0.extraordinary}
        }
        return result
    }
    
    var totalAmount: Decimal {
        filteredExpenses().reduce(0) { $0 + $1.value }
    }
    
    func deleteExpenses(at offsets: IndexSet, from expenses: [Expense]) async {
        guard let expenseBasket else { return }
        // Resolve the rows before awaiting: the list changes as each delete completes.
        let toDelete = offsets.map { expenses[$0] }
        do {
            for expense in toDelete {
                try await expenseBasket.delete(expense)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleExtraordinary(_ expense: Expense) async {
        guard let expenseBasket else { return }
        var updated = expense
        updated.extraordinary.toggle()
        do {
            try await expenseBasket.update(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func category(for expense: Expense) -> Category? {
        categories.category(withID: expense.categoryID)
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.categoryBasket = categoryBasket
        self.expenseBasket = expenseBasket
        // Both loads run in parallel; the screen only succeeds if both do. The state is set
        // from this call's results alone, so a later successful retry clears an earlier failure.
        async let categoriesLoaded = loadCategories()
        async let expensesLoaded = loadExpenses()
        let succeeded = await (categoriesLoaded, expensesLoaded) == (true, true)
        loadingState = succeeded ? .success : .failed
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

    /// Searches every loaded expense, not only the selected month.
    func latestCategory(forLocationName locationName: String) async -> Category? {
        categories.category(withID: expenseBasket?.latestCategoryID(forLocationName: locationName))
    }

    /// Loads expenses once; the shared basket keeps them up to date after each write.
    /// - Returns: `true` if expenses are available.
    private func loadExpenses() async -> Bool {
        guard let expenseBasket else { return false }
        do {
            try await expenseBasket.loadIfNeeded()
            return true
        } catch {
            return false
        }
    }

    /// Always re-fetches expenses from the server (e.g. pull-to-refresh).
    /// Categories are retried too if they failed before, so the screen can recover from either failure.
    func refreshExpenses() async {
        async let categoriesLoaded = loadCategories()
        async let expensesLoaded = reloadExpenses()
        let succeeded = await (categoriesLoaded, expensesLoaded) == (true, true)
        loadingState = succeeded ? .success : .failed
    }

    /// - Returns: `true` if the fresh fetch succeeded.
    private func reloadExpenses() async -> Bool {
        guard let expenseBasket else { return false }
        do {
            try await expenseBasket.getAllExpenses()
            return true
        } catch {
            return false
        }
    }

}
