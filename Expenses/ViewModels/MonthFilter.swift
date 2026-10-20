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

    let monthOffsets = Array(-3...3)

    func selectedMonth() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: monthOffsets[selectedMonthIndex], to: .now) ?? .now
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
