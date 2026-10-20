//
//  ExpenseFilterTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

import Testing
import Foundation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

struct ExpenseFilterTests {
    private let food = Category(id: 1, name: "Food")
    private let restaurants = Category(id: 2, name: "Restaurants", parentID: 1)
    private let transport = Category(id: 3, name: "Transport")
    private var categories: [Category] { [food, restaurants, transport] }

    private var expenses: [Expense] {
        [
            Expense(id: 1, categoryID: food.id, value: 10),
            Expense(id: 2, categoryID: restaurants.id, value: 20, extraordinary: true),
            Expense(id: 3, categoryID: transport.id, value: 30),
        ]
    }

    @Test func defaultFilterIsInactiveAndKeepsEverything() {
        let filter = ExpenseFilter()
        #expect(!filter.isActive)
        #expect(filter.apply(to: expenses, categories: categories).map(\.id) == [1, 2, 3])
    }

    @Test func categoryIncludesItsSubcategories() {
        let filter = ExpenseFilter(category: food)
        #expect(filter.isActive)
        #expect(filter.apply(to: expenses, categories: categories).map(\.id) == [1, 2])
    }

    @Test(arguments: [(ExtraOption.extra, [2]), (.regular, [1, 3])])
    func extraKeepsMatchingExpenses(extra: ExtraOption, expectedIDs: [Int]) {
        let filter = ExpenseFilter(extra: extra)
        #expect(filter.isActive)
        #expect(filter.apply(to: expenses, categories: categories).map(\.id) == expectedIDs)
    }

    @Test func categoryAndExtraCombine() {
        let filter = ExpenseFilter(category: food, extra: .regular)
        #expect(filter.apply(to: expenses, categories: categories).map(\.id) == [1])
    }
}
