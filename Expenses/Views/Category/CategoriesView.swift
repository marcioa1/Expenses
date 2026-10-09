//
//  CategoriesView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI

struct CategoriesView: View {
    @State private var viewModel = CategoriesViewModel()
    private let repository: any CategoryRepository

    init(repository: any CategoryRepository = CategoryRemoteDataProvider()) {
        self.repository = repository
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                CategoryGridView(
                    categories: viewModel.rootCategories(),
                    allCategories: viewModel.categories,
                    columns: columns,
                    onEdit: { category in viewModel.categoryToEdit = category }
                )
            }
            .task {
                await viewModel.configure(with: repository)
            }
            .refreshable {
                await viewModel.getAll()
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
                CategoryFormView(
                    categories: viewModel.categories,
                    repository: repository,
                    onSaved: { await viewModel.getAll() }
                )
            }
            .sheet(item: $viewModel.categoryToEdit) { category in
                CategoryFormView(
                    category: category,
                    categories: viewModel.categories,
                    repository: repository,
                    onSaved: { await viewModel.getAll() }
                )
            }
        }
    }
}

struct CategoryGridView: View {
    let categories: [Category]
    /// Full flat list, used to resolve each category's subcategories.
    let allCategories: [Category]
    let columns: [GridItem]
    let onEdit: (Category) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(categories) { category in
                let subcategories = allCategories.subcategories(of: category)
                if subcategories.isEmpty {
                    CategoryCardView(category: category)
                        .onTapGesture { onEdit(category) }
                } else {
                    NavigationLink {
                        SubcategoriesView(category: category, allCategories: allCategories, onEdit: onEdit)
                    } label: {
                        CategoryCardView(category: category, subcategoryCount: subcategories.count)
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
    let allCategories: [Category]
    let onEdit: (Category) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            CategoryGridView(
                categories: allCategories.subcategories(of: category),
                allCategories: allCategories,
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

#if DEBUG
#Preview {
    CategoriesView(repository: MockCategoryDataProvider())
}
#endif
