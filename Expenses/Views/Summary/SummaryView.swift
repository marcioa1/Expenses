//
//  SummaryView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 31/03/26.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query(sort: \Expense.datetime, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var viewModel = SummaryViewModel()

    var body: some View {
        NavigationStack {
            List {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )

                CategoryBreakdownView(
                    expensesByParent: viewModel.expensesByParent(from: allExpenses, categories: categories),
                    totalAmount: viewModel.totalAmount(from: allExpenses),
                    currencyCode: CurrencyHelper.code
                )

                RecentExpensesView(
                    expenses: Array(viewModel.filteredExpenses(from: allExpenses).prefix(7)),
                    expenseToEdit: $viewModel.expenseToEdit
                )
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarTotalView(
                        totalAmount: viewModel.totalAmount(from: allExpenses)
                    )
                }
            }
            .sheet(item: $viewModel.expenseToEdit) { expense in
                ExpenseFormView(expense: expense)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Expense.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let food = Category(name: "Food", categoryIcon: "fork.knife")
    let transport = Category(name: "Transport", categoryIcon: "car.fill")
    context.insert(food)
    context.insert(transport)
    context.insert(Expense(category: food, details: "Lunch", value: 25.50))
    context.insert(Expense(category: food, details: "Groceries", value: 87.30))
    context.insert(Expense(category: transport, value: 12.00))
    return SummaryView()
        .modelContainer(container)
}
