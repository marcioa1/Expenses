//
//  FilterView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedSort: SortOption?
    @Binding var selectedExtra: ExtraOption
    @Binding var selectedCategory: Category?
    let categories: [Category]
    private var hasSort: Bool {
        selectedSort != nil
    }
    private var sortBinding: Binding<SortOption> {
        Binding(
            get: { selectedSort ?? .date },
            set: { selectedSort = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {            
            CategoryPickerView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
            ExtraFilterView(selectedExtra: $selectedExtra)
                .padding(.vertical,  16)
            if hasSort {
                    SortPickerView(selectedSort: sortBinding)
            }
        }
        .padding(.horizontal)
    }
}

#Preview("With Sort") {
    @Previewable @State var selectedSort: SortOption? = .date
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

#Preview("No Sort") {
    @Previewable @State var selectedSort: SortOption? = nil
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
