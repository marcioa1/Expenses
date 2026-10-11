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
                    Label(category.name, systemImage: category.icon)
                        .tag(category as Category?)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    ]

    CategoryPickerView(selectedCategory: $selectedCategory, categories: categories)
        .padding()
}
