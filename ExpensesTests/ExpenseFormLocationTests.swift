//
//  ExpenseFormLocationTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 16/10/26.
//

import Testing
import Foundation
import CoreLocation
@testable import Expenses

/// Disambiguates from the Objective-C runtime `Category` type exposed by Foundation.
private typealias Category = Expenses.Category

/// Lets the location lookup reach the view model while it's "waiting for GPS".
private final class ViewModelBox {
    var viewModel: ExpenseFormViewModel?
}

struct ExpenseFormLocationTests {

    private let food = Category(id: 1, name: "Food")
    private let transport = Category(id: 2, name: "Transport")
    private let starbucks = PointOfInterest(
        name: "Starbucks",
        coordinate: CLLocationCoordinate2D(latitude: -23.5, longitude: -46.6),
        category: nil
    )

    /// A past expense at Starbucks, so `food` is the suggested category there.
    private func makeBaskets() -> (CategoryBasket, ExpenseBasket) {
        let pastExpense = Expense(id: 1, categoryID: food.id, value: 10, locationName: "Starbucks")
        return (
            CategoryBasket(categories: [food, transport]),
            ExpenseBasket(expenses: [pastExpense])
        )
    }

    @Test func fillsEmptyFieldsFromTheCurrentPlace() async {
        let (categoryBasket, expenseBasket) = makeBaskets()
        let vm = ExpenseFormViewModel(findPointOfInterest: { starbucks })

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)

        #expect(vm.locationName == "Starbucks")
        #expect(vm.latitude == -23.5)
        #expect(vm.longitude == -46.6)
        #expect(vm.selectedCategory == food)
    }

    @Test func keepsCategoryPickedWhileWaitingForGPS() async {
        let (categoryBasket, expenseBasket) = makeBaskets()
        let box = ViewModelBox()
        let vm = ExpenseFormViewModel(findPointOfInterest: { [transport, starbucks] in
            // The user picks a category before the location arrives.
            box.viewModel?.selectedCategory = transport
            return starbucks
        })
        box.viewModel = vm

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)

        #expect(vm.selectedCategory == transport)
        // The location field was still empty, so it's filled in.
        #expect(vm.locationName == "Starbucks")
    }

    @Test func keepsLocationTypedWhileWaitingForGPS() async {
        let (categoryBasket, expenseBasket) = makeBaskets()
        let box = ViewModelBox()
        let vm = ExpenseFormViewModel(findPointOfInterest: { [starbucks] in
            box.viewModel?.locationName = "Office"
            return starbucks
        })
        box.viewModel = vm

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)

        #expect(vm.locationName == "Office")
        #expect(vm.latitude == nil)
        #expect(vm.longitude == nil)
        // The suggestion came from the GPS place, which the user replaced, so it isn't applied.
        #expect(vm.selectedCategory == nil)
    }

    @Test func leavesFormUntouchedWhenNoPlaceIsFound() async {
        let (categoryBasket, expenseBasket) = makeBaskets()
        let vm = ExpenseFormViewModel(findPointOfInterest: { nil })

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)

        #expect(vm.locationName == "")
        #expect(vm.latitude == nil)
        #expect(vm.selectedCategory == nil)
    }

    @Test func editingDoesNotLookUpTheLocation() async {
        let (categoryBasket, expenseBasket) = makeBaskets()
        let expense = Expense(id: 2, categoryID: transport.id, value: 5, locationName: "Home")
        var lookups = 0
        let vm = ExpenseFormViewModel(expense: expense, findPointOfInterest: {
            lookups += 1
            return nil
        })

        await vm.configure(with: categoryBasket, expenseBasket: expenseBasket)

        #expect(lookups == 0)
        #expect(vm.locationName == "Home")
    }
}
