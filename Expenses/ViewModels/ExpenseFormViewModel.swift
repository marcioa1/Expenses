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
    /// Finds the place where the user is; replaceable so tests don't need real GPS.
    private let findPointOfInterest: () async -> PointOfInterest?

    var categories: [Category] {
        (categoryBasket?.categories ?? []).sorted { $0.name < $1.name }
    }

    var isEditing: Bool { expense != nil }

    var canSave: Bool {
        selectedCategory != nil && value != nil && value! > 0
    }

    func configure(with categoryBasket: CategoryBasket, expenseBasket: ExpenseBasket) async {
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

    /// - Parameter findPointOfInterest: Looks up the current place for new expenses.
    ///   Defaults to a `LocationManager`, created only when a location is actually needed.
    init(expense: Expense? = nil, findPointOfInterest: (() async -> PointOfInterest?)? = nil) {
        self.expense = expense
        self.findPointOfInterest = findPointOfInterest ?? {
            // Kept alive by this closure until the lookup finishes.
            let locationManager = LocationManager()
            return await locationManager.getPOI()
        }
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

    /// Pre-fills the location (and a suggested category) from where the user is.
    ///
    /// The GPS fix can take a few seconds, and the user may fill the form in the meantime.
    /// What to change is decided only after the lookup returns, and only empty fields are
    /// filled, so nothing the user typed or picked is overwritten.
    private func resolveLocation() async {
        guard let poi = await findPointOfInterest(), !poi.name.isEmpty else { return }

        // The user typed their own location: keep it, and don't attach the GPS coordinates,
        // since the place found may not be the one they wrote.
        guard locationName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        locationName = poi.name
        latitude = poi.coordinate.latitude
        longitude = poi.coordinate.longitude

        // Suggest the category last used at this place, unless the user already picked one.
        guard selectedCategory == nil else { return }
        let categoryID = expenseBasket?.latestCategoryID(forLocationName: poi.name)
        if let suggested = categories.category(withID: categoryID), suggested.isActive {
            selectedCategory = suggested
        }
    }

}
