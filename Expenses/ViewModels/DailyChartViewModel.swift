//
//  DailyChartViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import Foundation

struct DailyTotal: Identifiable {
    let id = UUID()
    let day: Int
    let total: Double
}

@Observable
class DailyChartViewModel: MonthFilterable {
    let monthFilter = MonthFilter()

    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set { monthFilter.selectedMonthIndex = newValue }
    }

    func daysInMonth() -> Int {
        let calendar = Calendar.current
        let date = monthFilter.selectedMonth()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func expensesByDay(from allExpenses: [Expense]) -> [DailyTotal] {
        let filtered = monthFilter.filteredExpenses(from: allExpenses)
        let calendar = Calendar.current

        var dailyMap: [Int: Double] = [:]
        for expense in filtered {
            let day = calendar.component(.day, from: expense.datetime)
            dailyMap[day, default: 0] += expense.value
        }

        let totalDays = daysInMonth()
        return (1...totalDays).map { day in
            DailyTotal(day: day, total: dailyMap[day] ?? 0)
        }
    }
}
