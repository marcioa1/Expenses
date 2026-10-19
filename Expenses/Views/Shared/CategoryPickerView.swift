//
//  CategoryPickerView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import SwiftUI

/// Category filter used by the Expenses, Chart and Grid tabs.
///
/// Unlike the expense form (which only offers active categories for new expenses), the filter
/// lists **every** category: inactive ones still have past expenses the user may want to see.
struct CategoryPickerView: View {
    @Binding var selectedCategory: Category?
    let categories: [Category]

    var body: some View {
        HStack {
            Text("Category")
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(nil as Category?)
                ForEach(categories) { category in
                    Label(title(for: category), systemImage: category.icon)
                        .tag(category as Category?)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Marks inactive categories, the same way the Categories screen does, so it's clear why
    /// they don't show up when adding a new expense.
    private func title(for category: Category) -> String {
        category.isActive ? category.name : "\(category.name) (\(String(localized: "Inactive")))"
    }
}

#Preview {
    @Previewable @State var selectedCategory: Category? = nil

    let categories = [
        Category(id: 1, name: "Food", icon: "fork.knife"),
        Category(id: 2, name: "Transport", icon: "car"),
        Category(id: 3, name: "Estacionamento", icon: "car"),
        Category(id: 4, name: "Shopping", icon: "cart"),
        Category(id: 5, name: "Health", icon: "heart"),
        Category(id: 6, name: "Gym", isActive: false, icon: "dumbbell.fill"),
    ]

    CategoryPickerView(selectedCategory: $selectedCategory, categories: categories)
        .padding()
}
