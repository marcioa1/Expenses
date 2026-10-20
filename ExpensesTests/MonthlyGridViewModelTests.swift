//
//  MonthlyGridViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct MonthlyGridViewModelTests {
    private let calendar = Calendar.current

    /// A date on `day` of the month `monthOffset` months from now.
    private func date(day: Int, monthOffset: Int = 0) -> Date {
        let month = calendar.date(byAdding: .month, value: monthOffset, to: .now)!
        var parts = calendar.dateComponents([.year, .month], from: month)
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts)!
    }

    private func makeViewModel(expenses: [Expense]) async -> MonthlyGridViewModel {
        let vm = MonthlyGridViewModel()
        await vm.configure(
            with: CategoryBasket(categories: [Category(id: 1, name: "Food")]),
            expenseBasket: ExpenseBasket(expenses: expenses)
        )
        return vm
    }

    @Test func showsTheLastThreeMonthsWithOneTotalPerDay() async throws {
        let grid = await makeViewModel(expenses: []).grid

        #expect(grid.columns.count == 3)
        let current = try #require(grid.columns.last)
        #expect(current.dayCount == calendar.range(of: .day, in: .month, for: .now)?.count)
        #expect(grid.maxDays == grid.columns.map(\.dayCount).max())
    }

    @Test func runningTotalsAddUpDayByDay() async throws {
        let grid = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: 1, value: 10, datetime: date(day: 2)),
            Expense(id: 2, categoryID: 1, value: 15, datetime: date(day: 4)),
        ]).grid

        let totals = try #require(grid.columns.last).runningTotals
        #expect(totals[0] == nil)   // Nothing spent yet on day 1.
        #expect(totals[1] == 10)
        #expect(totals[2] == 10)    // Day 3 carries day 2's total.
        #expect(totals[3] == 25)
        #expect(totals.last == 25)
    }

    @Test func maxTotalIsTheLargestMonthTotal() async {
        let grid = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: 1, value: 40, datetime: date(day: 5, monthOffset: -1)),
            Expense(id: 2, categoryID: 1, value: 25, datetime: date(day: 5)),
        ]).grid

        #expect(grid.maxTotal == 40)
        #expect(grid.intensity(of: 20) == 0.5)
    }

    @Test func maxTotalIsOneWithoutExpenses() async {
        #expect(await makeViewModel(expenses: []).grid.maxTotal == 1)
    }

    @Test func gridAppliesTheFilter() async {
        let vm = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: 1, value: 10, datetime: date(day: 1)),
            Expense(id: 2, categoryID: 1, value: 30, datetime: date(day: 1), extraordinary: true),
        ])
        #expect(vm.grid.columns.last?.runningTotals.last == 40)

        vm.filter.extra = .regular
        #expect(vm.grid.columns.last?.runningTotals.last == 10)
    }
}
