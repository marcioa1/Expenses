//
//  DailyChartViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import Foundation

struct DailyTotal: Identifiable {
    let day: Int
    let total: Decimal

    /// The day is unique within a month, so it stays the same across renders and the chart
    /// can match each bar to its previous value instead of treating every bar as new.
    var id: Int { day }

    /// Bar height for Swift Charts; only used for drawing, sums stay in `Decimal`.
    var plotTotal: Double {
        Double(truncating: total as NSDecimalNumber)
    }
}

@Observable
final class DailyChartViewModel: MonthFilterable {
    let monthFilter = MonthFilter()
    var filter = ExpenseFilter()
    /// Shared stores, provided by the view via `configure`.
    private var baskets: SharedBaskets?
    var categories: [Category] {
        baskets?.categoryBasket.categories ?? []
    }
    private var expenses: [Expense] {
        baskets?.expenseBasket.expenses ?? []
    }
    var loadingState: LoadingState {
        baskets?.loadingState ?? .loading
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        let baskets = SharedBaskets(categoryBasket: categoryBasket, expenseBasket: expenseBasket)
        self.baskets = baskets
        await baskets.loadIfNeeded()
    }

    func daysInMonth() -> Int {
        let calendar = Calendar.current
        let date = monthFilter.selectedMonth()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// One bar per day of the selected month, for the expenses matching `filter`.
    var dailyTotals: [DailyTotal] {
        let monthExpenses = monthFilter.filteredExpenses(from: expenses)
        let result = filter.apply(to: monthExpenses, categories: categories)
        let calendar = Calendar.current

        var dailyMap: [Int: Decimal] = [:]
        for expense in result {
            let day = calendar.component(.day, from: expense.datetime)
            dailyMap[day, default: 0] += expense.value
        }

        let totalDays = daysInMonth()
        return (1...totalDays).map { day in
            DailyTotal(day: day, total: dailyMap[day] ?? 0)
        }
    }
}
