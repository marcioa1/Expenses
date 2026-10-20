//
//  MonthlyGridViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import Foundation
import Observation

@Observable
final class MonthlyGridViewModel {
    private let calendar = Calendar.current
    let monthFilter = MonthFilter()
    /// Shared stores, provided by the view via `configure`.
    private var baskets: SharedBaskets?
    var categories: [Category] {
        baskets?.categoryBasket.categories ?? []
    }
    /// Expenses within the months shown in the grid.
    var expenses: [Expense] {
        guard let baskets, let range = displayedRange else { return [] }
        return baskets.expenseBasket.expenses(from: range.start, to: range.end)
    }
    var filter = ExpenseFilter()

    var loadingState: LoadingState {
        baskets?.loadingState ?? .loading
    }

    var filteredExpenses: [Expense] {
        filter.apply(to: expenses, categories: categories)
    }
    
    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        let baskets = SharedBaskets(categoryBasket: categoryBasket, expenseBasket: expenseBasket)
        self.baskets = baskets
        // Loads once; the shared baskets keep the data up to date after each write.
        await baskets.loadIfNeeded()
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
    
    var months: [Date] {
        (-2...0).compactMap { calendar.date(byAdding: .month, value: $0, to: .now) }
    }

    var maxDays: Int {
        months.map { daysInMonth($0) }.max() ?? 31
    }

    func daysInMonth(_ date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    func accumulated(through day: Int, in monthDate: Date, from expenses: [Expense]) -> Decimal? {
        guard day <= daysInMonth(monthDate) else { return nil }
        var comps = calendar.dateComponents([.year, .month], from: monthDate)
        comps.day = 1
        guard let startDate = calendar.date(from: comps) else { return nil }
        comps.day = day
        guard let endDate = calendar.date(from: comps) else { return nil }
        let sum = expenses
            .filter {
                let d = $0.datetime
                return d >= startDate && calendar.compare(d, to: endDate, toGranularity: .day) != .orderedDescending
            }
            .reduce(Decimal.zero) { $0 + $1.value }
        return sum > 0 ? sum : nil
    }

    var maxTotal: Decimal {
        var result = Decimal.zero
        for month in months {
            if let t = accumulated(through: daysInMonth(month), in: month, from: filteredExpenses) {
                result = Swift.max(result, t)
            }
        }
        return result > 0 ? result : 1
    }

    func monthLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
}
