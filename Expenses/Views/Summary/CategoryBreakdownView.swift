//
//  CategoryBreakdownView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/04/26.
//

import SwiftUI

struct CategoryBreakdownView: View {
    let groups: [CategoryGroup]
    let totalAmount: Decimal
    let currencyCode: String

    var body: some View {
        Section("By Category") {
            if groups.isEmpty {
                Text("No expenses in this period.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(groups) { group in
                    Group {
                        if group.hasChildren {
                            DisclosureGroup {
                                ForEach(group.subtotals) { item in
                                    SubcategoryRow(category: item.category, total: item.total, currencyCode: currencyCode)
                                }
                            } label: {
                                ParentCategoryRow(category: group.parent, total: group.total, totalAmount: totalAmount, currencyCode: currencyCode)
                            }
                        } else {
                            ParentCategoryRow(category: group.parent, total: group.total, totalAmount: totalAmount, currencyCode: currencyCode)
                        }
                    }
                    .listRowBackground(Color.secondary)
                }
            }
        }
        .tint(.secondary)
    }
}

private struct ParentCategoryRow: View {
    let category: Category
    let total: Decimal
    let totalAmount: Decimal
    let currencyCode: String

    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .categoryIconStyle()

            Text(category.name)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(total, format: .currency(code: currencyCode))
                    .font(.headline)

                if totalAmount > 0 {
                    Text(total / totalAmount, format: .percent.precision(.fractionLength(0)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SubcategoryRow: View {
    let category: Category
    let total: Decimal
    let currencyCode: String

    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .categoryIconStyle(width: 24)

            Text(category.name)
                .font(.subheadline)

            Spacer()

            Text(total, format: .currency(code: currencyCode))
                .font(.subheadline)
        }
        .padding(.leading, 8)
    }
}
