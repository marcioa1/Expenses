//
//  ExpenseRowView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack {
            Image(systemName: expense.category.categoryIcon)
                .font(.title3)
                .categoryIconStyle(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category.name)
                    .font(.headline)

                if let details = expense.details, !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(expense.datetime, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expense.value, format: .currency(code: CurrencyHelper.code))
                .font(.headline)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.secondary)
    }
}
