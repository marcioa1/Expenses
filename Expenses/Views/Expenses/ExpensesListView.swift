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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )
                
                FilterView(
                    selectedSort: $viewModel.selectedSort,
                    selectedCategory: $viewModel.selectedCategory,
                    categories: viewModel.categories ?? []
                )
                .padding(16)
                
                switch viewModel.loadingState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    Text("deu ruim")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success:
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
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarTotalView(
                        totalAmount: viewModel.totalAmount
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
        }
        .task {
            await viewModel.configure(modelContext: modelContext)
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
