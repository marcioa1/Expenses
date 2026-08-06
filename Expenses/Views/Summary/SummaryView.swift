//
//  SummaryView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 31/03/26.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SummaryViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )
                switch viewModel.loadingState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    Text("deu ruim")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success:
                    
                    successContent
                    
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarTotalView(
                        totalAmount: viewModel.totalAmount(from: viewModel.expenses)
                    )
                }
            }
            .sheet(item: $viewModel.expenseToEdit) { expense in
                ExpenseFormView(expense: expense)
            }
            .task {
                await viewModel.configure(modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private var successContent: some View {
        List {
            CategoryBreakdownView(
                expensesByParent: viewModel.expensesByParent(),
                totalAmount: viewModel.totalAmount(from: viewModel.expenses),
                currencyCode: CurrencyHelper.code
            )
            RecentExpensesView(
                expenses: Array(viewModel.filteredExpenses(from: viewModel.expenses).prefix(7)),
                expenseToEdit: $viewModel.expenseToEdit
            )
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
