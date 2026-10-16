//
//  DailyChartViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

@MainActor
struct DailyChartViewModelTests {

    @Test func dailyTotalsAreIdentifiedByDay() {
        let vm = DailyChartViewModel()
        let expenses = [Expense(id: 1, categoryID: 1, value: 10)]

        let totals = vm.expensesByDay(from: expenses)

        #expect(totals.map(\.id) == Array(1...vm.daysInMonth()))
        #expect(Set(totals.map(\.id)).count == totals.count)
    }

    @Test func dailyTotalIDsAreStableAcrossCalls() {
        let vm = DailyChartViewModel()
        let expenses = [Expense(id: 1, categoryID: 1, value: 10)]

        let first = vm.expensesByDay(from: expenses).map(\.id)
        let second = vm.expensesByDay(from: expenses).map(\.id)

        #expect(first == second)
    }
}
