//
//  MonthFilterTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct MonthFilterTests {
    private let calendar = Calendar.current

    @Test func offersSevenMonthsCenteredOnTheCurrentOne() {
        let filter = MonthFilter()
        let currentLabel = Date.now.formatted(.dateTime.month(.wide)).capitalized

        #expect(filter.monthLabels.count == 7)
        #expect(filter.monthLabels[filter.selectedMonthIndex] == currentLabel)
    }

    @Test func labelsFollowTheSelectedMonth() {
        let filter = MonthFilter()
        filter.selectedMonthIndex = 0

        let expected = filter.selectedMonth().formatted(.dateTime.month(.wide)).capitalized
        #expect(filter.monthLabels[0] == expected)
        #expect(calendar.dateComponents([.month], from: filter.selectedMonth()).month
                == calendar.dateComponents([.month], from: calendar.date(byAdding: .month, value: -3, to: .now)!).month)
    }

    @Test func filteredExpensesKeepsOnlyTheSelectedMonth() {
        let filter = MonthFilter()
        let thisMonth = Expense(id: 1, categoryID: 1, value: 10)
        let lastMonth = Expense(id: 2, categoryID: 1, value: 20, datetime: calendar.date(byAdding: .month, value: -1, to: .now)!)

        #expect(filter.filteredExpenses(from: [thisMonth, lastMonth]).map(\.id) == [1])
    }
}
