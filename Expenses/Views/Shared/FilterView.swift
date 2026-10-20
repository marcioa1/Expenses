//
//  FilterView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSort: SortOption?
    @Binding var filter: ExpenseFilter
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
            HStack {
                Text("Filters")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 4)

            CategoryPickerView(
                selectedCategory: $filter.category,
                categories: categories
            )
            ExtraFilterView(selectedExtra: $filter.extra)
                .padding(.vertical, 16)
            if hasSort {
                SortPickerView(selectedSort: sortBinding)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

extension View {
    /// Presents `FilterView` as a short bottom sheet.
    /// - Parameter selectedSort: Pass a binding to show the sort picker; leave it `nil` to hide it.
    func filterSheet(
        isPresented: Binding<Bool>,
        filter: Binding<ExpenseFilter>,
        selectedSort: Binding<SortOption?> = .constant(nil),
        categories: [Category]
    ) -> some View {
        sheet(isPresented: isPresented) {
            FilterView(selectedSort: selectedSort, filter: filter, categories: categories)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview("With Sort") {
    @Previewable @State var selectedSort: SortOption? = .date
    @Previewable @State var filter = ExpenseFilter()
    
    let categories = [
        Category(id: 1, name: "Food", icon: "fork.knife"),
        Category(id: 2, name: "Transport", icon: "car"),
        Category(id: 3, name: "Shopping", icon: "cart"),
    ]
    
    FilterView(
        selectedSort: $selectedSort,
        filter: $filter,
        categories: categories
    )
}

#Preview("No Sort") {
    @Previewable @State var filter = ExpenseFilter()

    let categories = [
        Category(id: 1, name: "Food", icon: "fork.knife"),
        Category(id: 2, name: "Transport", icon: "car"),
        Category(id: 3, name: "Shopping", icon: "cart"),
    ]

    FilterView(
        selectedSort: .constant(nil),
        filter: $filter,
        categories: categories
    )
}
