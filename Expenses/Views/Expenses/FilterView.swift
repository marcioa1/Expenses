//
//  FilterView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedSort: SortOption
    @Binding var selectedCategory: Category?
    let categories: [Category]

    var body: some View {
        HStack(spacing: 8) {
            CategoryPickerView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
            Spacer()
            SortPickerView(selectedSort: $selectedSort)
                .frame(width: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.tertiary)
        .cornerRadius(16)
    }
}

#Preview {
    @Previewable @State var selectedSort: SortOption = .date
    @Previewable @State var selectedCategory: Category? = nil

    let categories = [
        Category(name: "Food", categoryIcon: "fork.knife"),
        Category(name: "Transport", categoryIcon: "car"),
        Category(name: "Shopping", categoryIcon: "cart"),
    ]

    FilterView(
        selectedSort: $selectedSort,
        selectedCategory: $selectedCategory,
        categories: categories
    )
}
