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
    @State private var viewModel = ExpensesListViewModel()
    @State private var showingFilter = false

    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil ||
        viewModel.selectedExtra != .all ||
        viewModel.selectedSort != .date
    }

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
                    ErrorView()
                case .success:
                    expenseList
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarTotalView(
                        totalAmount: viewModel.totalAmount
                    )
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilter = true
                    } label: {
                        Image(systemName: hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterView(
                    selectedSort: $viewModel.selectedSort,
                    selectedExtra: $viewModel.selectedExtra,
                    selectedCategory: $viewModel.selectedCategory,
                    categories: viewModel.categories ?? []
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showingForm, onDismiss: {
                Task { await viewModel.refreshExpenses() }
            }) {
                ExpenseFormView()
            }
            .sheet(item: $viewModel.expenseToEdit, onDismiss: {
                Task { await viewModel.refreshExpenses() }
            }) { expense in
                ExpenseFormView(expense: expense)
            }
        }
        .task {
            await viewModel.configure(modelContext: modelContext)
        }
    }
    
    @ViewBuilder
    private var expenseList: some View {
        List {
            ForEach(viewModel.filteredExpenses()) { expense in
                ExpenseRowView(expense: expense)
                    .onTapGesture {
                        viewModel.expenseToEdit = expense
                    }
            }
            .onDelete { offsets in
                viewModel.deleteExpenses(at: offsets, from: viewModel.filteredExpenses(), in: modelContext)
            }
        }
        .overlay {
            if viewModel.expenses.isEmpty {
                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "creditcard",
                    description: Text("Add your first expense to get started.")
                )
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
