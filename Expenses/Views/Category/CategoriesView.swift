//
//  CategoriesView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CategoriesViewModel()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                CategoryGridView(
                    categories: viewModel.rootCategories(),
                    columns: columns,
                    onEdit: { category in viewModel.categoryToEdit = category }
                )
            }
            .task {
                await viewModel.configure(modelContext: modelContext)
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingForm) {
                CategoryFormView()
            }
            .sheet(item: $viewModel.categoryToEdit) { category in
                CategoryFormView(category: category)
            }
        }
    }
}

struct CategoryGridView: View {
    let categories: [Category]
    let columns: [GridItem]
    let onEdit: (Category) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(categories) { category in
                if category.subcategories.isEmpty {
                    CategoryCardView(category: category)
                        .onTapGesture { onEdit(category) }
                } else {
                    NavigationLink {
                        SubcategoriesView(category: category, onEdit: onEdit)
                    } label: {
                        CategoryCardView(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
    }
}

struct SubcategoriesView: View {
    let category: Category
    let onEdit: (Category) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var sortedSubcategories: [Category] {
        category.subcategories.sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            CategoryGridView(
                categories: sortedSubcategories,
                columns: columns,
                onEdit: onEdit
            )
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onEdit(category)
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    context.insert(Category(name: "Food", categoryIcon: "fork.knife"))
    context.insert(Category(name: "Transport", categoryIcon: "car.fill"))
    context.insert(Category(name: "Entertainment", categoryIcon: "gamecontroller.fill"))
    context.insert(Category(name: "Health", categoryIcon: "heart.fill"))
    context.insert(Category(name: "Shopping", categoryIcon: "bag.fill"))
    return CategoriesView()
        .modelContainer(container)
}
