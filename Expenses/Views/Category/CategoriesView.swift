//
//  CategoriesView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(CategoryBasket.self) private var categoryBasket
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
                    allCategories: viewModel.categories,
                    columns: columns,
                    onEdit: { category in viewModel.categoryToEdit = category }
                )
            }
            .task {
                await viewModel.configure(with: categoryBasket)
            }
            .refreshable {
                await viewModel.refresh()
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
                CategoryFormView(categoryBasket: categoryBasket)
            }
            .sheet(item: $viewModel.categoryToEdit) { category in
                CategoryFormView(category: category, categoryBasket: categoryBasket)
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
    CategoriesView()
        .environment(CategoryBasket(categoryRepository: MockCategoryDataProvider()))
}
#endif
