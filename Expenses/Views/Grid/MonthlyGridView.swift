//
//  MonthlyGridView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import SwiftUI

struct MonthlyGridView: View {
    @Environment(CategoryBasket.self) private var categoryBasket
    @Environment(ExpenseBasket.self) private var expenseBasket
    @State private var viewModel = MonthlyGridViewModel()
    @State private var showingFilter = false

    /// Called when the user taps the logout button.
    var onLogout: () -> Void = {}

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    ErrorView()
                case .success:
                    gridContent
                }
            }
            .navigationTitle("Monthly Overview")
            .toolbar {
                FilterToolbarItem(isActive: viewModel.filter.isActive) {
                    showingFilter = true
                }
                LogoutToolbarItem(onLogout: onLogout)
            }
            .filterSheet(
                isPresented: $showingFilter,
                filter: $viewModel.filter,
                categories: viewModel.categories
            )
        }
        .task {
            await viewModel.configure(with: categoryBasket, expenseBasket: expenseBasket)
        }
    }

    private var gridContent: some View {
        // Only computed when the grid is actually drawn, not while loading or after a failure.
        let maxTotal = viewModel.maxTotal
        return ScrollView {
            Grid(alignment: .trailing, horizontalSpacing: 6, verticalSpacing: 0) {
                headerRow
                ForEach(1...viewModel.maxDays, id: \.self) { day in
                    Divider()
                    GridRow {
                        Text(String(format: "%02d", day))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.leading)
                        ForEach(viewModel.months, id: \.self) { month in
                            cell(day: day, month: month, maxTotal: maxTotal)
                        }
                    }
                    .frame(height: 40)
                }
            }
            .padding()
        }
    }

    private var headerRow: some View {
        GridRow {
            Text("Day")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            ForEach(viewModel.months, id: \.self) { month in
                Text(viewModel.monthLabel(month))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func cell(day: Int, month: Date, maxTotal: Decimal) -> some View {
        if day > viewModel.daysInMonth(month) {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 36)
        } else {
            let amount = viewModel.accumulated(through: day, in: month, from: viewModel.filteredExpenses)
            // A 0...1 ratio used only for the cell's opacity, so `Double` precision is fine here.
            let intensity = amount.map { Double(truncating: ($0 / maxTotal) as NSDecimalNumber) } ?? 0

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(intensity > 0
                          ? Color.accentColor.opacity(0.15 + intensity * 0.65)
                          : Color(.systemFill))

                if let amount {
                    Text(amount, format: .currency(code: CurrencyHelper.code).precision(.fractionLength(0)))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(intensity > 0.5 ? .white : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 4)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
        }
    }
}

#Preview {
    let food = Category(id: 1, name: "Food", icon: "fork.knife")
    let transport = Category(id: 2, name: "Transport", icon: "car.fill")
    let calendar = Calendar.current
    var expenses: [Expense] = []
    for monthOffset in -2...0 {
        for day in stride(from: 1, through: 28, by: 3) {
            guard let month = calendar.date(byAdding: .month, value: monthOffset, to: .now) else { continue }
            var comps = calendar.dateComponents([.year, .month], from: month)
            comps.day = day
            guard let date = calendar.date(from: comps) else { continue }
            // Random amounts in cents, so every value has exactly two decimal places.
            expenses.append(Expense(id: expenses.count + 1, categoryID: food.id, value: Decimal(Int.random(in: 1_000...20_000)) / 100, datetime: date))
            expenses.append(Expense(id: expenses.count + 1, categoryID: transport.id, value: Decimal(Int.random(in: 500...15_000)) / 100, datetime: date))
        }
    }
    return MonthlyGridView()
        .environment(CategoryBasket(categories: [food, transport]))
        .environment(ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: expenses)))
}
