//
//  MonthFilterable.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import Foundation

protocol MonthFilterable: AnyObject {
    var monthFilter: MonthFilter { get }
}

extension MonthFilterable {
    var monthOffsets: [Int] { monthFilter.monthOffsets }

    func filteredExpenses(from allExpenses: [Expense]) -> [Expense] {
        monthFilter.filteredExpenses(from: allExpenses)
    }

    func totalAmount(from allExpenses: [Expense]) -> Double {
        monthFilter.totalAmount(from: allExpenses)
    }
}
