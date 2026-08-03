//
//  ExpenseFormView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 31/03/26.
//

import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.name) private var categories: [Category]

    @State private var viewModel: ExpenseFormViewModel

    init(expense: Expense? = nil) {
        _viewModel = State(initialValue: ExpenseFormViewModel(expense: expense))
    }
    var body: some View {
        @State var isSaving: Bool = false
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Select a category").tag(nil as Category?)
                        ForEach(viewModel.leafCategories(from: categories)) { category in
                            Label(category.name, systemImage: category.categoryIcon)
                                .tag(category as Category?)
                        }
                    }
                }

                Section("Value") {
                    TextField("Amount", value: $viewModel.value, format: .currency(code: CurrencyHelper.code))
                        .keyboardType(.decimalPad)
                }

                Section("Details") {
                    TextField("Description (optional)", text: $viewModel.details)
                }

                Section("Date & Time") {
                    DatePicker("Date", selection: $viewModel.datetime)
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
                        isSaving = true
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                        }
                        viewModel.save(in: modelContext)
                        isSaving = false
                        dismiss()
                    } label: {
                        Text("Save")
                            .opacity(isSaving ? 0 : 1)
                            .overlay {
                                if isSaving {
                                    ProgressView()
                                }
                            }
                    }
                    .disabled(!viewModel.canSave || isSaving)
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            let container = try! ModelContainer(for: Expense.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = container.mainContext
            context.insert(Category(name: "Food", categoryIcon: "fork.knife"))
            context.insert(Category(name: "Transport", categoryIcon: "car.fill"))
            return ExpenseFormView()
                .modelContainer(container)
        }
    }
    return PreviewWrapper()
}
