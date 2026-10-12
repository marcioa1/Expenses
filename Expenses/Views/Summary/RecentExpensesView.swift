//
//  RecentExpensesView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/04/26.
//

import SwiftUI

struct RecentExpensesView: View {
    let expenses: [Expense]
    let categories: [Category]
    @Binding var expenseToEdit: Expense?

    var body: some View {
        Section("Recent Expenses") {
            if expenses.isEmpty {
                Text("No expenses in this period.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(expenses) { expense in
                    ExpenseRowView(expense: expense, category: categories.category(withID: expense.categoryID))
                        .onTapGesture {
                            expenseToEdit = expense
                        }
                }
            }
        }
    }
}
