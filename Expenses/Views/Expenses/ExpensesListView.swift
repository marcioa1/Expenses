//
//  ExpensesListView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import SwiftUI
import SwiftData

struct ExpensesListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.datetime, order: .reverse) private var expenses: [Expense]

    @State private var viewModel = ExpensesListViewModel()

    private var filteredExpenses: [Expense] {
        viewModel.filteredExpenses(from: expenses)
    }
    
    var body: some View {
        NavigationStack {
            List {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )

                Section {
                    CategoryPickerView(
                        selectedCategory: $viewModel.selectedCategory,
                        categories: viewModel.categories ?? []
                    )
                }

                ForEach(filteredExpenses) { expense in
                    ExpenseRowView(expense: expense)
                        .onTapGesture {
                            viewModel.expenseToEdit = expense
                        }
                        
                }
                .onDelete { offsets in
                    viewModel.deleteExpenses(at: offsets, from: filteredExpenses, in: modelContext)
                }
            }
            .overlay {
                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "creditcard",
                        description: Text("Add your first expense to get started.")
                    )
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarTotalView(
                        totalAmount: viewModel.totalAmount(from: expenses)
                    )
                }
              
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingForm) {
                ExpenseFormView()
            }
            .sheet(item: $viewModel.expenseToEdit) { expense in
                ExpenseFormView(expense: expense)
            }
            .task {
                await viewModel.configure(modelContext: modelContext)
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
    context.insert(Expense(category: food, details: "Lunch at restaurant", value: 25.50))
    context.insert(Expense(category: transport, value: 1200.00))
    context.insert(Expense(category: food, details: "Groceries", value: 87.30))
    return ExpensesListView()
        .modelContainer(container)
}
