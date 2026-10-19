//
//  SummaryViewModelTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct SummaryViewModelTests {

    @Test func configureSucceedsWhenBothLoadsSucceed() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .success)
    }

    @Test func configureFailsWhenOnlyCategoriesFail() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider(fetchError: APIError.network)),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func configureFailsWhenOnlyExpensesFail() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider(fetchError: APIError.network))
        )
        #expect(vm.loadingState == .failed)
    }

    @Test func changingMonthKeepsLoadedState() async {
        let vm = SummaryViewModel()
        await vm.configure(
            with: CategoryBasket(categoryRepository: MockCategoryDataProvider()),
            expenseBasket: ExpenseBasket(expenseRepository: MockExpenseDataProvider())
        )
        vm.selectedMonthIndex = 0
        #expect(vm.loadingState == .success)
    }
}
