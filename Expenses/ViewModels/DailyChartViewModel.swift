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

/// The selected month laid out as a calendar: where day 1 falls in the first week, and each day's total.
struct CalendarMonth {
    let days: [DailyTotal]
    /// Empty cells before day 1, so it lands under its weekday (follows the locale's first weekday).
    let leadingBlankDays: Int
    /// Short weekday names, starting at the locale's first weekday.
    let weekdaySymbols: [String]
    /// Today's day number, or `nil` when another month is shown.
    var today: Int?

    /// The largest daily total, used to scale each cell's color; never zero, so it's safe to divide by.
    var maxTotal: Decimal {
        let largest = days.map(\.total).max() ?? 0
        return largest > 0 ? largest : 1
    }

    /// A 0...1 ratio used only for a cell's opacity, so `Double` precision is fine here.
    func intensity(of amount: Decimal) -> Double {
        Double(truncating: (amount / maxTotal) as NSDecimalNumber)
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

    /// The selected month's expenses matching `filter`, newest first.
    private var filteredMonthExpenses: [Expense] {
        filter.apply(to: monthFilter.filteredExpenses(from: expenses), categories: categories)
    }

    /// One bar per day of the selected month, for the expenses matching `filter`.
    var dailyTotals: [DailyTotal] {
        let calendar = Calendar.current

        var dailyMap: [Int: Decimal] = [:]
        for expense in filteredMonthExpenses {
            let day = calendar.component(.day, from: expense.datetime)
            dailyMap[day, default: 0] += expense.value
        }

        let totalDays = daysInMonth()
        return (1...totalDays).map { day in
            DailyTotal(day: day, total: dailyMap[day] ?? 0)
        }
    }

    // MARK: - Calendar

    /// The daily totals arranged for a week-by-week calendar of the selected month.
    var calendarMonth: CalendarMonth {
        let calendar = Calendar.current
        // `firstWeekday` is 1-based (1 = Sunday); rotate the symbols so the week starts there.
        let firstWeekdayIndex = calendar.firstWeekday - 1
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let weekdaySymbols = Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])

        let weekdayOfDayOne = date(ofDay: 1).map { calendar.component(.weekday, from: $0) } ?? calendar.firstWeekday
        let leadingBlankDays = (weekdayOfDayOne - calendar.firstWeekday + 7) % 7

        let isCurrentMonth = calendar.isDate(monthFilter.selectedMonth(), equalTo: .now, toGranularity: .month)
        let today = isCurrentMonth ? calendar.component(.day, from: .now) : nil

        return CalendarMonth(
            days: dailyTotals,
            leadingBlankDays: leadingBlankDays,
            weekdaySymbols: weekdaySymbols,
            today: today
        )
    }

    /// The given day of the selected month, at midnight.
    func date(ofDay day: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: monthFilter.selectedMonth())
        components.day = day
        return calendar.date(from: components)
    }

    /// The expenses of one day of the selected month matching `filter`, newest first.
    func expenses(onDay day: Int) -> [Expense] {
        let calendar = Calendar.current
        return filteredMonthExpenses.filter { calendar.component(.day, from: $0.datetime) == day }
    }

    func category(for expense: Expense) -> Category? {
        categories.category(withID: expense.categoryID)
    }
}
