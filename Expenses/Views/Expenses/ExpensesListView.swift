//
//  ExpensesListView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import SwiftUI

struct ExpensesListView: View {
    
    @Environment(CategoryBasket.self) private var categoryBasket
    @Environment(ExpenseBasket.self) private var expenseBasket
    @State private var viewModel = ExpensesListViewModel()
    @State private var showingFilter = false

    /// Called when the user taps the logout button.
    var onLogout: () -> Void = {}

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

                FilterToolbarItem(isActive: viewModel.hasActiveFilters) {
                    showingFilter = true
                }
                LogoutToolbarItem(onLogout: onLogout)

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .filterSheet(
                isPresented: $showingFilter,
                filter: $viewModel.filter,
                selectedSort: $viewModel.selectedSort,
                categories: viewModel.categories
            )
            // The form writes through the shared basket, so the list updates without a refresh.
            .sheet(isPresented: $viewModel.showingForm) {
                ExpenseFormView()
            }
            .sheet(item: $viewModel.expenseToEdit) { expense in
                ExpenseFormView(expense: expense)
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await viewModel.configure(with: categoryBasket, expenseBasket: expenseBasket)
        }
    }
    
    @ViewBuilder
    private var expenseList: some View {
        // Filtered and sorted once per render, then shared by the rows, delete and the empty state.
        let rows = viewModel.filteredExpenses()
        List {
            ForEach(rows) { expense in
                ExpenseRowView(expense: expense, category: viewModel.category(for: expense))
                    .onTapGesture {
                        viewModel.expenseToEdit = expense
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await viewModel.toggleExtraordinary(expense) }
                        } label: {
                            Label(
                                expense.extraordinary ? "Unmark Extra" : "Mark Extra",
                                systemImage: expense.extraordinary ? "minus.circle" : "plus.circle"
                            )
                        }
                        .tint(.yellow)
                    }
            }
            .onDelete { offsets in
                // `offsets` index the rows on screen, which are exactly `rows`.
                Task { await viewModel.deleteExpenses(at: offsets, from: rows) }
            }
        }
        .refreshable {
            await viewModel.refreshExpenses()
        }
        .overlay {
            if viewModel.expenses.isEmpty && viewModel.hasAnyExpenses {
                // Other months have expenses; only the selected one is empty.
                ContentUnavailableView(
                    "No Expenses This Month",
                    systemImage: "calendar",
                    description: Text("Choose another month or add a new expense.")
                )
            } else if viewModel.expenses.isEmpty {
                // Nothing recorded yet, in any month.
                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "creditcard",
                    description: Text("Add your first expense to get started.")
                )
            } else if rows.isEmpty {
                // The month has expenses, but none match the category / extra filters.
                ContentUnavailableView(
                    "No Matching Expenses",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try changing the filters.")
                )
            }
        }
    }
}

#Preview {
    let food = Category(id: 1, name: "Food", icon: "fork.knife")
    let transport = Category(id: 2, name: "Transport", icon: "car.fill")
    let expenses = [
        Expense(id: 1, categoryID: food.id, details: "Lunch at restaurant", value: 25.50),
        Expense(id: 2, categoryID: transport.id, value: 1200.00),
        Expense(id: 3, categoryID: food.id, details: "Groceries", value: 87.30)
    ]
    ExpensesListView()
        .environment(CategoryBasket(categories: [food, transport]))
        .environment(ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: expenses)))
}
