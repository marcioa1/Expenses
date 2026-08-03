//
//  MonthlyGridViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import Foundation

@Observable
class MonthlyGridViewModel {
    private let calendar = Calendar.current

    var months: [Date] {
        (-2...0).compactMap { calendar.date(byAdding: .month, value: $0, to: .now) }
    }

    var maxDays: Int {
        months.map { daysInMonth($0) }.max() ?? 31
    }

    func daysInMonth(_ date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    func accumulated(through day: Int, in monthDate: Date, from expenses: [Expense]) -> Double? {
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
            .reduce(0.0) { $0 + $1.value }
        return sum > 0 ? sum : nil
    }

    func maxTotal(from expenses: [Expense]) -> Double {
        var result = 0.0
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
