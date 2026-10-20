//
//  MonthFilter.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/04/26.
//

import Foundation

@Observable
class MonthFilter {
    var selectedMonthIndex: Int = 3

    /// The months offered, relative to the current one: three before and three after.
    private let monthOffsets = Array(-3...3)

    /// One label per offered month, e.g. "Outubro", in the same order as `selectedMonthIndex`.
    var monthLabels: [String] {
        monthOffsets.map { month(at: $0).formatted(.dateTime.month(.wide)).capitalized }
    }

    func selectedMonth() -> Date {
        month(at: monthOffsets[selectedMonthIndex])
    }

    private func month(at offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: .now) ?? .now
    }

    private func monthStart() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth())
        return calendar.date(from: components) ?? selectedMonth()
    }

    private func monthEnd() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: DateComponents(month: 1, second: -1), to: monthStart()) ?? selectedMonth()
    }

    /// The expenses of the selected month. The single month filter used by every tab.
    func filteredExpenses(from allExpenses: [Expense]) -> [Expense] {
        let start = monthStart()
        let end = monthEnd()
        return allExpenses.filter { $0.datetime >= start && $0.datetime <= end }
    }
}
