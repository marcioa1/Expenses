//
//  SummaryView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 31/03/26.
//

import SwiftUI

@MainActor
struct SummaryView: View {
    @Environment(CategoryBasket.self) private var categoryBasket
    @Environment(ExpenseBasket.self) private var expenseBasket
    @State private var viewModel: SummaryViewModel

    /// Called when the user taps the logout button.
    var onLogout: () -> Void = {}

    init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
        _viewModel = State(wrappedValue: SummaryViewModel())
    }

    init(viewModel: SummaryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        onLogout()
                    }
                }
            }
            .sheet(item: $viewModel.expenseToEdit) { expense in
                ExpenseFormView(expense: expense)
            }
            .task {
                await viewModel.configure(with: categoryBasket, expenseBasket: expenseBasket)
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
                categories: viewModel.categories,
                expenseToEdit: $viewModel.expenseToEdit
            )
        }
    }
}

#Preview("Error") {
    SummaryView(viewModel: SummaryViewModel(previewState: .failed))
        .environment(CategoryBasket())
        .environment(ExpenseBasket())
}

#Preview("Success") {
    let food = Category(id: 1, name: "Food", icon: "fork.knife")
    let transport = Category(id: 2, name: "Transport", icon: "car.fill")
    let expenses = [
        Expense(id: 1, categoryID: food.id, details: "Lunch", value: 25.50),
        Expense(id: 2, categoryID: food.id, details: "Groceries", value: 87.30),
        Expense(id: 3, categoryID: transport.id, value: 12.00)
    ]
    return SummaryView()
        .environment(CategoryBasket(categories: [food, transport]))
        .environment(ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: expenses)))
}
