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
        Picker("Category", selection: $selectedCategory) {
            Text("All").tag(nil as Category?)
            ForEach(categories.filter { $0.isActive }) { category in
                Label(category.name, systemImage: category.categoryIcon)
                    .tag(category as Category?)
            }
        }
    }
}
