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

    /// Called when the user taps the logout button.
    var onLogout: () -> Void = {}

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    ErrorView()
                case .success:
                    categoryGrid
                }
            }
            .task {
                await viewModel.configure(with: categoryBasket)
            }
            .navigationTitle("Categories")
            .toolbar {
                LogoutToolbarItem(onLogout: onLogout)

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
    }

    private var categoryGrid: some View {
        ScrollView {
            CategoryGridView(
                categories: viewModel.rootCategories(),
                allCategories: viewModel.categories,
                columns: columns,
                onEdit: { category in viewModel.categoryToEdit = category }
            )
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.categories.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "square.grid.2x2",
                    description: Text("Add your first category to organize your expenses.")
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
    CategoriesView()
        .environment(CategoryBasket(categoryRepository: MockCategoryDataProvider()))
}
#endif
