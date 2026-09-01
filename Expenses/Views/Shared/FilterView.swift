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
        VStack(alignment: .leading, spacing: 8) {
//            Text("Filters")
//                .font(.title2.bold())
//                .padding(.horizontal)
//                .padding(.top, 8)
            
            CategoryPickerView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
            ExtraFilterView(selectedExtra: $selectedExtra)
            SortPickerView(selectedSort: $selectedSort)
        }
        .background(.yellow)
        .padding(.horizontal)
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
