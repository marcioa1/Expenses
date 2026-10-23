//
//  ExpenseFormView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 31/03/26.
//

import SwiftUI

struct ExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CategoryBasket.self) private var categoryBasket
    @Environment(ExpenseBasket.self) private var expenseBasket

    @State private var viewModel: ExpenseFormViewModel
    @FocusState private var isValueFocused: Bool

    init(expense: Expense? = nil) {
        _viewModel = State(initialValue: ExpenseFormViewModel(expense: expense))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Select a category").tag(nil as Category?)
                        ForEach(viewModel.selectableCategories()) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category as Category?)
                        }
                    }
                    .onChange(of: viewModel.selectedCategory) { _, _ in
                        isValueFocused = true
                    }
                }

                Section("Value") {
                    TextField("Amount", value: $viewModel.value, format: .currency(code: CurrencyHelper.code))
                        .keyboardType(.decimalPad)
                        .focused($isValueFocused)
                }

                Section("Details / Location") {
                    TextField("Description (optional)", text: $viewModel.details)
                    HStack {
                        TextField("Location (optional)", text: $viewModel.locationName)
                        if !viewModel.locationName.isEmpty {
                            Button("Clear Location", systemImage: "xmark.circle.fill") {
                                viewModel.clearLocation()
                            }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.secondary)
                            .buttonStyle(.borderless)
                        }
                    }
                }

                Section("Details") {
                    DatePicker("Date", selection: $viewModel.datetime)
                    Toggle("Extraordinary", isOn: $viewModel.extraordinary)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // The form only closes once the expense is saved on the server.
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Save")
                            .opacity(viewModel.isSaving ? 0 : 1)
                            .overlay {
                                if viewModel.isSaving {
                                    ProgressView()
                                }
                            }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert(
                "Couldn't save expense",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .interactiveDismissDisabled(viewModel.isSaving)
            .task {
                await viewModel.configure(with: categoryBasket, expenseBasket: expenseBasket)
            }
        }
    }
}

#Preview {
    ExpenseFormView()
        .environment(CategoryBasket(categories: [
            Category(id: 1, name: "Food", icon: "fork.knife"),
            Category(id: 2, name: "Transport", icon: "car.fill")
        ]))
        .environment(ExpenseBasket(expenseRepository: MockExpenseDataProvider()))
}
