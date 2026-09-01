//
//  CategoryPickerView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: Category?
    let categories: [Category]

    var body: some View {
        HStack {
            Text("Category")
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(nil as Category?)
                ForEach(categories.filter { $0.isActive }) { category in
                    Label(category.name, systemImage: category.categoryIcon)
                        .tag(category as Category?)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

#Preview {
    @Previewable @State var selectedCategory: Category? = nil

    let categories = [
        Category(name: "Food", categoryIcon: "fork.knife"),
        Category(name: "Transport", categoryIcon: "car"),
        Category(name: "Estacionamento", categoryIcon: "car"),
        Category(name: "Shopping", categoryIcon: "cart"),
        Category(name: "Health", categoryIcon: "heart"),
    ]

    CategoryPickerView(selectedCategory: $selectedCategory, categories: categories)
        .padding()
}
