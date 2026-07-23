//
//  CategoryFormView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.name) private var categories: [Category]
    @State private var viewModel: CategoryFormViewModel

    init(category: Category? = nil) {
        _viewModel = State(initialValue: CategoryFormViewModel(category: category))
    }

    private var availableParents: [Category] {
        categories.filter { $0.id != viewModel.category?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $viewModel.name)
                        .onChange(of: viewModel.name) {
                            viewModel.validateName(in: modelContext)
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
                        ForEach(availableParents) { category in
                            Label(category.name, systemImage: category.categoryIcon)
                                .tag(category as Category?)
                        }
                    }
                }

                if let category = viewModel.category, !category.subcategories.isEmpty {
                    Section("Subcategories") {
                        ForEach(category.subcategories.sorted(by: { $0.name < $1.name })) { child in
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
                    Button("Save") {
                        viewModel.save(in: modelContext)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

#Preview("New") {
    CategoryFormView()
        .modelContainer(for: Category.self, inMemory: true)
}

#Preview("Edit") {
    let container = try! ModelContainer(for: Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let category = Category(name: "Food", categoryIcon: "fork.knife")
    container.mainContext.insert(category)
    return CategoryFormView(category: category)
        .modelContainer(container)
}
