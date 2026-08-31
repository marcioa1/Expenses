//
//  FilterView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedSort: SortOption
    @Binding var selectedExtra: ExtraOption
    @Binding var selectedCategory: Category?
    let categories: [Category]

    var body: some View {
        VStack(alignment: .leading) {
            CategoryPickerView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
            HStack(spacing: 8) {
                ExtraFilterView(selectedExtra: $selectedExtra)
                Spacer()
                SortPickerView(selectedSort: $selectedSort)
                    .frame(width: 120)
            }
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
    @Previewable @State var selectedExtra: ExtraOption = .all
    @Previewable @State var selectedCategory: Category? = nil

    let categories = [
        Category(name: "Food", categoryIcon: "fork.knife"),
        Category(name: "Transport", categoryIcon: "car"),
        Category(name: "Shopping", categoryIcon: "cart"),
    ]

    FilterView(
        selectedSort: $selectedSort,
        selectedExtra: $selectedExtra,
        selectedCategory: $selectedCategory,
        categories: categories
    )
}
