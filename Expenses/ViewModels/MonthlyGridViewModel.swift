//
//  MonthlyGridViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import Foundation
import Observation

/// One column of the grid: a month and how much had been spent by the end of each of its days.
struct MonthColumn: Identifiable {
    let month: Date
    let label: String
    /// Index 0 is day 1, with one entry per day of the month. `nil` until something is spent that month.
    let runningTotals: [Decimal?]

    var id: Date { month }
    var dayCount: Int { runningTotals.count }
}

/// Everything the grid draws, computed in one pass over the expenses.
struct MonthlyGrid {
    let columns: [MonthColumn]

    /// Rows to draw: the longest month shown.
    var maxDays: Int {
        columns.map(\.dayCount).max() ?? 31
    }

    /// The largest month total, used to scale each cell's color; never zero, so it's safe to divide by.
    var maxTotal: Decimal {
        let largest = columns.compactMap { $0.runningTotals.last ?? nil }.max() ?? 0
        return largest > 0 ? largest : 1
    }

    /// A 0...1 ratio used only for a cell's opacity, so `Double` precision is fine here.
    func intensity(of amount: Decimal) -> Double {
        Double(truncating: (amount / maxTotal) as NSDecimalNumber)
    }
}

@Observable
final class MonthlyGridViewModel {
    private let calendar = Calendar.current
    /// Shared stores, provided by the view via `configure`.
    private var baskets: SharedBaskets?
    var categories: [Category] {
        baskets?.categoryBasket.categories ?? []
    }
    var filter = ExpenseFilter()

    var loadingState: LoadingState {
        baskets?.loadingState ?? .loading
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        let baskets = SharedBaskets(categoryBasket: categoryBasket, expenseBasket: expenseBasket)
        self.baskets = baskets
        // Loads once; the shared baskets keep the data up to date after each write.
        await baskets.loadIfNeeded()
    }

    /// The last three months, oldest first.
    private var months: [Date] {
        (-2...0).compactMap { calendar.date(byAdding: .month, value: $0, to: .now) }
    }

    /// Running totals of the filtered expenses for each displayed month.
    var grid: MonthlyGrid {
        guard let baskets, let range = displayedRange else { return MonthlyGrid(columns: []) }
        let expenses = baskets.expenseBasket.expenses(from: range.start, to: range.end)

        // Total spent on each day, grouped by month, in a single pass.
        var dailySums: [Int: [Int: Decimal]] = [:]
        for expense in filter.apply(to: expenses, categories: categories) {
            let day = calendar.component(.day, from: expense.datetime)
            dailySums[monthKey(expense.datetime), default: [:]][day, default: 0] += expense.value
        }

        let columns = months.map { month in
            let sums = dailySums[monthKey(month)] ?? [:]
            var runningTotal = Decimal.zero
            let runningTotals: [Decimal?] = (1...daysInMonth(month)).map { day in
                runningTotal += sums[day] ?? 0
                return runningTotal > 0 ? runningTotal : nil
            }
            return MonthColumn(month: month, label: monthLabel(month), runningTotals: runningTotals)
        }
        return MonthlyGrid(columns: columns)
    }

    /// From the first day of the oldest month to the last second of the newest month shown.
    private var displayedRange: (start: Date, end: Date)? {
        guard let firstMonth = months.first, let lastMonth = months.last else { return nil }
        var startComps = calendar.dateComponents([.year, .month], from: firstMonth)
        startComps.day = 1
        guard let start = calendar.date(from: startComps),
              let lastMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)),
              let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: lastMonthStart) else { return nil }
        return (start, end)
    }

    /// Identifies a calendar month, e.g. 202610 for October 2026.
    private func monthKey(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return (parts.year ?? 0) * 100 + (parts.month ?? 0)
    }

    private func daysInMonth(_ date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private func monthLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
}
