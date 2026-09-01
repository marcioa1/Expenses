//
//  MonthlyGridViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 23/07/26.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class MonthlyGridViewModel {
    private let calendar = Calendar.current
    let monthFilter = MonthFilter()
    var categories: [Category]?
    var expenses: [Expense] = []
    var selectedCategory: Category?
    var loadingState: LoadingState = .loading
    private var categoryRepository: (any DataProvider)?
    private var expenseRepository: ExpenseLocalDataProvider?
    
    var filteredExpenses: [Expense] {
        if let selectedCategory {
            self.expenses.filter { $0.category.id == selectedCategory.id || $0.category.parent?.id == selectedCategory.id  }
        } else {
            self.expenses
        }
    }
    
    func configure(modelContext: ModelContext) async {
        categoryRepository = CategoryLocalDataProvider(modelContext: modelContext)
        expenseRepository = ExpenseLocalDataProvider(modelContext: modelContext)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getAllCategories() }
            group.addTask { await self.refreshExpenses() }
        }
        if loadingState != .failed {
            loadingState = .success
        }
    }

    private func getAllCategories() async {
        guard let categoryRepository else { return }
        do {
            categories = try await categoryRepository.fetchAll() as? [Category]
        } catch {
            loadingState = .failed
        }
    }
    
    func refreshExpenses() async {
        try? await Task.sleep(for: .seconds(1))
        guard let expenseRepository, let firstMonth = months.first, let lastMonth = months.last else { return }
        var startComps = calendar.dateComponents([.year, .month], from: firstMonth)
        startComps.day = 1
        guard let start = calendar.date(from: startComps),
              let lastMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)),
              let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: lastMonthStart) else { return }
        do {
            expenses = try await expenseRepository.fetch(from: start, to: end)
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }
    
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
