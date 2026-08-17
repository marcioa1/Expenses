//
//  MonthlyGridView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import SwiftUI
import SwiftData

struct MonthlyGridView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MonthlyGridViewModel()

    var body: some View {
        let maxTotal = viewModel.maxTotal(from: viewModel.filteredExpenses)
        NavigationStack {
            HStack {
                Spacer()
                
                CategoryPickerView(
                    selectedCategory: $viewModel.selectedCategory,
                    categories:
                        viewModel.categories ?? []
                )
                .pickerStyle(.menu)
                .padding(16)
            }
            ScrollView {
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
            .navigationTitle("Monthly Overview")
        }
        .task {
            await viewModel.configure(modelContext: modelContext)
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
    private func cell(day: Int, month: Date, maxTotal: Double) -> some View {
        if day > viewModel.daysInMonth(month) {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 36)
        } else {
            let amount = viewModel.accumulated(through: day, in: month, from: viewModel.filteredExpenses)
            let intensity = amount.map { $0 / maxTotal } ?? 0

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
    let container = try! ModelContainer(
        for: Expense.self, Category.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let food = Category(name: "Food", categoryIcon: "fork.knife")
    let transport = Category(name: "Transport", categoryIcon: "car.fill")
    context.insert(food)
    context.insert(transport)

    let calendar = Calendar.current
    let now = Date.now
    for monthOffset in -2...0 {
        guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: now) else { continue }
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 28
        for _ in 1...8 {
            let day = Int.random(in: 1...daysInMonth)
            var comps = calendar.dateComponents([.year, .month], from: monthDate)
            comps.day = day
            if let date = calendar.date(from: comps) {
                context.insert(Expense(category: food, value: Double.random(in: 10...200), datetime: date))
                context.insert(Expense(category: transport, value: Double.random(in: 5...150), datetime: date))
            }
        }
    }

    return MonthlyGridView()
        .modelContainer(container)
}
