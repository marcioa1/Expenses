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
    let total: Decimal

    /// Bar height for Swift Charts; only used for drawing, sums stay in `Decimal`.
    var plotTotal: Double {
        Double(truncating: total as NSDecimalNumber)
    }
}

@MainActor
@Observable
class DailyChartViewModel: MonthFilterable {
    let monthFilter = MonthFilter()
    var selectedCategory: Category?
    var selectedExtra: ExtraOption = .all
    private var categoryBasket: CategoryBasket?
    var categories: [Category] {
        categoryBasket?.categories ?? []
    }
    private var expenseBasket: ExpenseBasket?
    var expenses: [Expense] {
        expenseBasket?.expenses ?? []
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.categoryBasket = categoryBasket
        self.expenseBasket = expenseBasket
        async let categories: Void? = try? categoryBasket.loadIfNeeded()
        async let expenses: Void? = try? expenseBasket.loadIfNeeded()
        _ = await (categories, expenses)
    }

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

        var result = filtered
        if let selectedCategory {
            let ids = categories.ids(matching: selectedCategory)
            result = result.filter { ids.contains($0.categoryID) }
        }
        switch selectedExtra {
        case .all:
            break
        case .extra:
            result = result.filter { $0.extraordinary }
        case .regular:
            result = result.filter { !$0.extraordinary}
        }
        var dailyMap: [Int: Decimal] = [:]
        for expense in result {
            let day = calendar.component(.day, from: expense.datetime)
            dailyMap[day, default: 0] += expense.value
        }

        let totalDays = daysInMonth()
        return (1...totalDays).map { day in
            DailyTotal(day: day, total: dailyMap[day] ?? 0)
        }
    }
}
