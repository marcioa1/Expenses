//
//  MonthlyGridViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import Foundation
import Observation

@MainActor
@Observable
class MonthlyGridViewModel {
    private let calendar = Calendar.current
    let monthFilter = MonthFilter()
    private var categoryBasket: CategoryBasket?
    var categories: [Category] {
        categoryBasket?.categories ?? []
    }
    private var expenseBasket: ExpenseBasket?
    /// Expenses within the months shown in the grid.
    var expenses: [Expense] {
        guard let expenseBasket, let range = displayedRange else { return [] }
        return expenseBasket.expenses(from: range.start, to: range.end)
    }
    var selectedCategory: Category?
    var selectedExtra: ExtraOption = .all

    /// Derived from the shared baskets, so every tab agrees on whether the data is available.
    var loadingState: LoadingState {
        guard let categoryBasket, let expenseBasket else { return .loading }
        return .combined(categoryBasket.loadState, expenseBasket.loadState)
    }

    var filteredExpenses: [Expense] {
        var result = expenses
        if let selectedCategory {
            let ids = categories.ids(matching: selectedCategory)
            result = self.expenses.filter { ids.contains($0.categoryID) }
        }
        switch selectedExtra {
        case .all:
            break
        case .extra:
            result = result.filter { $0.extraordinary }
        case .regular:
            result = result.filter { !$0.extraordinary}
        }
        return result
    }
    
    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.categoryBasket = categoryBasket
        self.expenseBasket = expenseBasket
        // Loads once; the shared baskets keep the data up to date after each write.
        // Errors are reflected in each basket's `loadState`, which `loadingState` reads.
        async let categories: Void? = try? categoryBasket.loadIfNeeded()
        async let expenses: Void? = try? expenseBasket.loadIfNeeded()
        _ = await (categories, expenses)
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

    func maxTotal(from expenses: [Expense]) -> Decimal {
        var result = Decimal.zero
        for month in months {
            if let t = accumulated(through: daysInMonth(month), in: month, from: expenses) {
                result = Swift.max(result, t)
            }
        }
        return result > 0 ? result : 1
    }

    func monthLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
}
