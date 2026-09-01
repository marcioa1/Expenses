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
                .overlay(alignment: .topTrailing) {
                    if expense.extraordinary {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                            .offset(x: 4, y: -4)
                    }
                }

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

                if let locationName = expense.locationName {
                    Label(locationName, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(expense.value, format: .currency(code: CurrencyHelper.code))
                .font(.headline)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.secondary)
    }
}

#Preview("Regular") {
    let category = Category(name: "Food", categoryIcon: "fork.knife")
    let expense = Expense(
        category: category,
        details: "Lunch at the office",
        value: 42.50,
        locationName: "Café Central"
    )
    List {
        ExpenseRowView(expense: expense)
    }
}

#Preview("Extraordinary") {
    let category = Category(name: "Travel", categoryIcon: "airplane")
    let expense = Expense(
        category: category,
        value: 1250.00,
        extraordinary: true
    )
    List {
        ExpenseRowView(expense: expense)
    }
}
