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

    func configure(categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.categoryBasket = categoryBasket
        self.expenseBasket = expenseBasket
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getAllCategories() }
            group.addTask { await self.loadExpenses() }
        }
        if loadingState != .failed {
            loadingState = .success
        }
    }
    
    private func getAllCategories() async {
        guard let categoryBasket else { return }
        do {
            try await categoryBasket.loadIfNeeded()
        } catch {
            loadingState = .failed
        }
    }
    
    /// Searches every loaded expense, not only the selected month.
    func latestCategory(forLocationName locationName: String) async -> Category? {
        categories.category(withID: expenseBasket?.latestCategoryID(forLocationName: locationName))
    }

    /// Loads expenses once; the shared basket keeps them up to date after each write.
    private func loadExpenses() async {
        guard let expenseBasket else { return }
        do {
            try await expenseBasket.loadIfNeeded()
        } catch {
            loadingState = .failed
        }
    }

    /// Always re-fetches expenses from the server (e.g. pull-to-refresh).
    func refreshExpenses() async {
        guard let expenseBasket else { return }
        do {
            try await expenseBasket.getAllExpenses()
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }

}
