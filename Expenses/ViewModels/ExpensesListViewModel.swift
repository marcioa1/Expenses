//
//  ExpensesListViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation

@Observable
final class ExpensesListViewModel: MonthFilterable {
    var showingForm = false
    var expenseToEdit: Expense?
    var selectedCategory: Category?
    var selectedSort: SortOption? = .date
    var selectedExtra: ExtraOption = .all
    let monthFilter = MonthFilter()
    /// Message of the last failed write (delete / update) or refresh, shown as an alert by the view.
    var errorMessage: String?

    /// Derived from the shared baskets, so every tab agrees on whether the data is available.
    var loadingState: LoadingState {
        guard let categoryBasket, let expenseBasket else { return .loading }
        return .combined(categoryBasket.loadState, expenseBasket.loadState)
    }

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

    /// Whether the user has any expense at all, in any month. Lets the empty state tell
    /// "nothing recorded yet" apart from "nothing in this month".
    var hasAnyExpenses: Bool {
        !(expenseBasket?.expenses.isEmpty ?? true)
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
        // Errors are reflected in each basket's `loadState`, which `loadingState` reads.
        async let categories: Void? = try? categoryBasket.loadIfNeeded()
        async let expenses: Void? = try? expenseBasket.loadIfNeeded()
        _ = await (categories, expenses)
    }

    /// Searches every loaded expense, not only the selected month.
    func latestCategory(forLocationName locationName: String) async -> Category? {
        categories.category(withID: expenseBasket?.latestCategoryID(forLocationName: locationName))
    }

    /// Always re-fetches expenses from the server (pull-to-refresh); categories are loaded too if
    /// they never were. If the refresh fails, the data already on screen is kept and `errorMessage`
    /// tells the user it couldn't be refreshed.
    func refreshExpenses() async {
        async let categoriesLoaded = loadCategoriesIfNeeded()
        async let expensesRefreshed = refreshAllExpenses()
        let succeeded = await (categoriesLoaded, expensesRefreshed) == (true, true)
        if !succeeded {
            errorMessage = String(localized: "Couldn't refresh the data. Showing the last loaded data.")
        }
    }

    /// - Returns: `true` if categories are available.
    private func loadCategoriesIfNeeded() async -> Bool {
        guard let categoryBasket else { return false }
        do {
            try await categoryBasket.loadIfNeeded()
            return true
        } catch {
            return false
        }
    }

    /// - Returns: `true` if the fresh fetch succeeded.
    private func refreshAllExpenses() async -> Bool {
        guard let expenseBasket else { return false }
        do {
            try await expenseBasket.getAllExpenses()
            return true
        } catch {
            return false
        }
    }

}
