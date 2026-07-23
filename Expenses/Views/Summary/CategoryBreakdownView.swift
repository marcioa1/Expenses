//
//  CategoryBreakdownView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/04/26.
//

import SwiftUI

struct CategoryBreakdownView: View {
    let expensesByParent: [(parent: Category, subtotals: [(category: Category, total: Double)], total: Double)]
    let totalAmount: Double
    let currencyCode: String

    var body: some View {
        Section("By Category") {
            if expensesByParent.isEmpty {
                Text("No expenses in this period.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(expensesByParent, id: \.parent.id) { group in
                    DisclosureGroup {
                        ForEach(group.subtotals, id: \.category.id) { item in
                            HStack {
                                Image(systemName: item.category.categoryIcon)
                                    .categoryIconStyle(width: 24)

                                Text(item.category.name)
                                    .font(.subheadline)

                                Spacer()

                                Text(item.total, format: .currency(code: currencyCode))
                                    .font(.subheadline)
                            }
                            .padding(.leading, 8)
                        }
                    } label: {
                        HStack {
                            Image(systemName: group.parent.categoryIcon)
                                .categoryIconStyle()

                            Text(group.parent.name)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(group.total, format: .currency(code: currencyCode))
                                    .font(.headline)

                                if totalAmount > 0 {
                                    Text("\(Int((group.total / totalAmount) * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.secondary)
                }
            }
        }
        .tint(.secondary)
    }
}
