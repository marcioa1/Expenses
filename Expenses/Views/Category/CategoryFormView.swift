//
//  CategoryFormView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: CategoryFormViewModel
    private let onSaved: () async -> Void

    init(
        category: Category? = nil,
        categories: [Category],
        repository: any CategoryRepository,
        onSaved: @escaping () async -> Void = {}
    ) {
        _viewModel = State(initialValue: CategoryFormViewModel(
            category: category,
            categories: categories,
            repository: repository
        ))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $viewModel.name)
                        .onChange(of: viewModel.name) {
                            viewModel.validateName()
                        }
                } header: {
                    Text("Name")
                } footer: {
                    if let error = viewModel.nameError {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section("Icon") {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(viewModel.iconOptions, id: \.self) { iconName in
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(viewModel.icon == iconName ? Color.orange.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        viewModel.icon = iconName
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(height: 200)
                }

                Section("Parent Category") {
                    Picker("Parent", selection: $viewModel.parent) {
                        Text("None").tag(nil as Category?)
                        ForEach(viewModel.availableParents) { category in
                            Label(category.name, systemImage: category.categoryIcon)
                                .tag(category as Category?)
                        }
                    }
                }

                if !viewModel.subcategories.isEmpty {
                    Section("Subcategories") {
                        ForEach(viewModel.subcategories) { child in
                            Label(child.name, systemImage: child.categoryIcon)
                        }
                    }
                }

                Section {
                    Toggle("Active", isOn: $viewModel.isActive)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                await onSaved()
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
                "Unable to save category",
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
    }
}

#if DEBUG
#Preview("New") {
    CategoryFormView(categories: [], repository: MockCategoryDataProvider())
}

#Preview("Edit") {
    let food = Category(name: "Food", categoryIcon: "fork.knife")
    let restaurants = Category(name: "Restaurants", categoryIcon: "cup.and.saucer.fill", parentID: food.id)
    CategoryFormView(
        category: food,
        categories: [food, restaurants],
        repository: MockCategoryDataProvider(categories: [food, restaurants])
    )
}
#endif
