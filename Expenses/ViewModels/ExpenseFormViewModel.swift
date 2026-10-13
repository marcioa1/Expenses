//
//  ExpenseFormViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation
import MapKit

@MainActor
@Observable
class ExpenseFormViewModel {
    var selectedCategory: Category?
    var details: String = ""
    var value: Decimal?
    var datetime: Date = .now
    var locationName: String = ""
    var latitude: Double?
    var longitude: Double?
    var extraordinary: Bool = false

    let expense: Expense?
    private var categoryBasket: CategoryBasket?
    private var expenseBasket: ExpenseBasket?
    private let locationManager = LocationManager()

    var categories: [Category] {
        (categoryBasket?.categories ?? []).sorted { $0.name < $1.name }
    }

    var isEditing: Bool { expense != nil }

    var canSave: Bool {
        selectedCategory != nil && value != nil && value! > 0
    }

    func configure(categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
        self.expenseBasket = expenseBasket
        await configure(with: categoryBasket)
        if !isEditing {
            // Expenses are needed to suggest a category for the current location.
            try? await expenseBasket.loadIfNeeded()
            await resolveLocation()
        }
    }

    func configure(with categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        try? await categoryBasket.loadIfNeeded()
        if let expense {
            selectedCategory = categoryBasket.category(withID: expense.categoryID)
        }
    }

    func leafCategories() -> [Category] {
        categories.filter { categories.subcategories(of: $0).isEmpty }
    }
    
    func activeCategories() -> [Category] {
        categories.filter{ $0.isActive }
    }

    /// Leaf categories the user can pick. New expenses only see active categories;
    /// when editing, the expense's current category stays visible even if it has
    /// since been deactivated, so the picker selection remains valid.
    func selectableCategories() -> [Category] {
        leafCategories().filter { category in
            category.isActive || (isEditing && category.id == expense?.categoryID)
        }
    }

    init(expense: Expense? = nil) {
        self.expense = expense
        // `selectedCategory` is resolved from `expense.categoryID` once categories are fetched.
        if let expense {
            self.details = expense.details ?? ""
            self.value = expense.value
            self.datetime = expense.datetime
            self.locationName = expense.locationName ?? ""
            self.latitude = expense.latitude
            self.longitude = expense.longitude
            self.extraordinary = expense.extraordinary
        }
    }

    /// Creates or updates the expense through the shared basket, which sends it to the server.
    func save() async throws {
        guard let expenseBasket, let selectedCategory, let value else { return }
        let trimmedDetails = details.trimmingCharacters(in: .whitespaces)
        let trimmedLocation = locationName.trimmingCharacters(in: .whitespaces)
        if var updated = expense {
            updated.categoryID = selectedCategory.id
            updated.details = trimmedDetails.isEmpty ? nil : trimmedDetails
            updated.value = value
            updated.datetime = datetime
            updated.locationName = trimmedLocation.isEmpty ? nil : trimmedLocation
            updated.latitude = latitude
            updated.longitude = longitude
            updated.extraordinary = extraordinary
            try await expenseBasket.update(updated)
        } else {
            let draft = ExpenseDraft(
                categoryID: selectedCategory.id,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails,
                value: value,
                datetime: datetime,
                latitude: latitude,
                longitude: longitude,
                locationName: trimmedLocation.isEmpty ? nil : trimmedLocation,
                extraordinary: extraordinary
            )
            try await expenseBasket.create(draft)
        }
    }

    private func resolveLocation() async {
        let poi = await locationManager.getPOI()
        latitude = poi?.coordinate.latitude
        longitude = poi?.coordinate.longitude
        let name = poi?.name ?? ""
        locationName = name
        if !name.isEmpty {
            let categoryID = expenseBasket?.latestCategoryID(forLocationName: name)
            if let suggested = categories.category(withID: categoryID), suggested.isActive {
                selectedCategory = suggested
            }
        }
    }

}
