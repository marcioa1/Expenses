//
//  DailyChartViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct DailyChartViewModelTests {

    // MARK: - Daily totals

    /// A view model on the current month, backed by in-memory baskets that load right away.
    private func makeViewModel(expenses: [Expense]) async -> DailyChartViewModel {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categories: [Category(id: 1, name: "Food")]),
            expenseBasket: ExpenseBasket(expenses: expenses)
        )
        return vm
    }

    @Test func dailyTotalsAreIdentifiedByDay() async {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 1, value: 10)])

        let totals = vm.dailyTotals

        #expect(totals.map(\.id) == Array(1...vm.daysInMonth()))
        #expect(Set(totals.map(\.id)).count == totals.count)
    }

    @Test func dailyTotalIDsAreStableAcrossCalls() async {
        let vm = await makeViewModel(expenses: [Expense(id: 1, categoryID: 1, value: 10)])

        #expect(vm.dailyTotals.map(\.id) == vm.dailyTotals.map(\.id))
    }

    @Test func dailyTotalsSumTheDayAndApplyTheFilter() async {
        let vm = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: 1, value: 10),
            Expense(id: 2, categoryID: 1, value: 15, extraordinary: true),
        ])
        let today = Calendar.current.component(.day, from: .now)

        #expect(vm.dailyTotals.first { $0.day == today }?.total == 25)

        vm.filter.extra = .regular
        #expect(vm.dailyTotals.first { $0.day == today }?.total == 10)
    }

    // MARK: - Calendar

    @Test func calendarStartsDayOneUnderItsWeekday() async throws {
        let vm = await makeViewModel(expenses: [])
        let calendar = Calendar.current
        let dayOne = try #require(vm.date(ofDay: 1))

        let month = vm.calendarMonth

        // Counting `leadingBlankDays` on from the locale's first weekday reaches day 1's weekday.
        let weekday = (calendar.firstWeekday - 1 + month.leadingBlankDays) % 7 + 1
        #expect(weekday == calendar.component(.weekday, from: dayOne))
        #expect((0..<7).contains(month.leadingBlankDays))
        #expect(month.weekdaySymbols.count == 7)
        #expect(month.weekdaySymbols.first == calendar.shortStandaloneWeekdaySymbols[calendar.firstWeekday - 1])
        #expect(month.days.count == vm.daysInMonth())
    }

    @Test func calendarMarksTodayOnlyInTheCurrentMonth() async {
        let vm = await makeViewModel(expenses: [])

        #expect(vm.calendarMonth.today == Calendar.current.component(.day, from: .now))

        vm.selectedMonthIndex -= 1
        #expect(vm.calendarMonth.today == nil)
    }

    @Test func calendarIntensityIsRelativeToTheBusiestDay() {
        let month = CalendarMonth(
            days: [DailyTotal(day: 1, total: 50), DailyTotal(day: 2, total: 200), DailyTotal(day: 3, total: 0)],
            leadingBlankDays: 0,
            weekdaySymbols: []
        )

        #expect(month.intensity(of: 200) == 1)
        #expect(month.intensity(of: 50) == 0.25)
        #expect(month.intensity(of: 0) == 0)
    }

    @Test func calendarIntensityIsZeroForAnEmptyMonth() {
        let month = CalendarMonth(days: [DailyTotal(day: 1, total: 0)], leadingBlankDays: 0, weekdaySymbols: [])

        #expect(month.intensity(of: 0) == 0)
    }

    @Test func expensesOnDayKeepOnlyThatDayAndApplyTheFilter() async throws {
        let calendar = Calendar.current
        let today = calendar.component(.day, from: .now)
        // Another day of the same month, so it's in the selected month but not today.
        let otherDay = today == 1 ? 2 : 1
        let vm = await makeViewModel(expenses: [])
        let otherDate = try #require(vm.date(ofDay: otherDay))

        let filtered = await makeViewModel(expenses: [
            Expense(id: 1, categoryID: 1, value: 10),
            Expense(id: 2, categoryID: 1, value: 15, extraordinary: true),
            Expense(id: 3, categoryID: 1, value: 99, datetime: otherDate),
        ])

        #expect(Set(filtered.expenses(onDay: today).map(\.id)) == [1, 2])
        #expect(filtered.expenses(onDay: otherDay).map(\.id) == [3])

        filtered.filter.extra = .regular
        #expect(filtered.expenses(onDay: today).map(\.id) == [1])
    }

    @Test func dateOfDayIsInTheSelectedMonth() async throws {
        let vm = await makeViewModel(expenses: [])
        vm.selectedMonthIndex -= 1

        let date = try #require(vm.date(ofDay: 1))

        #expect(Calendar.current.isDate(date, equalTo: vm.monthFilter.selectedMonth(), toGranularity: .month))
        #expect(Calendar.current.component(.day, from: date) == 1)
    }

    // MARK: - Loading state

    @Test func startsLoading() {
        #expect(DailyChartViewModel().loadingState == .loading)
    }

    @Test func configureSucceedsWhenBothLoadsSucceed() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .success)
    }

    @Test func configureFailsWhenCategoriesFail() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureFailsWhenExpensesFail() async {
        let vm = DailyChartViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider(fetchError: APIError.network))
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureRecoversOnRetry() async {
        let vm = DailyChartViewModel()
        let categoryBasket = CategoryBasket(categoryRepository: MockCategoryDataProvider(failingFetches: 1))
        let expenseBasket = ExpenseBasket(expenseRepository: MockExpenseDataProvider())

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .failed)

        // E.g. the user comes back to the tab, which runs `configure` again.
        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)
        #expect(vm.loadingState == .success)
    }
}
