//
//  ExpenseFormViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import SwiftData
import Observation
import MapKit

@MainActor
@Observable
class ExpenseFormViewModel {
    var selectedCategory: Category?
    var details: String = ""
    var value: Double?
    var datetime: Date = .now
    var locationName: String = ""
    var latitude: Double?
    var longitude: Double?
    var extraordinary: Bool = false

    let expense: Expense?
    private var categoryBasket: CategoryBasket?
    private var expenseRepository: ExpenseLocalDataProvider?
    private let locationManager = LocationManager()

    var categories: [Category] {
        (categoryBasket?.categories ?? []).sorted { $0.name < $1.name }
    }

    var isEditing: Bool { expense != nil }

    var canSave: Bool {
        selectedCategory != nil && value != nil && value! > 0
    }

    func configure(modelContext: ModelContext, categoryBasket: CategoryBasket) async {
        expenseRepository = ExpenseLocalDataProvider(modelContext: modelContext)
        await configure(with: categoryBasket)
        if !isEditing {
            await resolveLocation()
        }
    }

    func configure(with categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        try? await categoryBasket.loadIfNeeded()
        if let expense {
            selectedCategory = categoryBasket.category(withID: expense.remoteCategoryID)
        }
    }

    func leafCategories() -> [Category] {
        categories.filter { categories.subcategories(of: $0).isEmpty }
    }

    init(expense: Expense? = nil) {
        self.expense = expense
        // `selectedCategory` is resolved from `expense.remoteCategoryID` once categories are fetched.
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

    func save(in context: ModelContext) {
        guard let selectedCategory, let value else { return }
        let trimmedDetails = details.trimmingCharacters(in: .whitespaces)
        let trimmedLocation = locationName.trimmingCharacters(in: .whitespaces)
        if let expense {
            expense.remoteCategoryID = selectedCategory.id
            expense.details = trimmedDetails.isEmpty ? nil : trimmedDetails
            expense.value = value
            expense.datetime = datetime
            expense.locationName = trimmedLocation.isEmpty ? nil : trimmedLocation
            expense.latitude = latitude
            expense.longitude = longitude
            expense.extraordinary = extraordinary
        } else {
            let newExpense = Expense(
                remoteCategoryID: selectedCategory.id,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails,
                value: value,
                datetime: datetime,
                latitude: latitude,
                longitude: longitude,
                locationName: trimmedLocation.isEmpty ? nil : trimmedLocation,
                extraordinary: extraordinary
            )
            context.insert(newExpense)
        }
    }

    private func resolveLocation() async {
        let poi = await locationManager.getPOI()
        latitude = poi?.coordinate.latitude
        longitude = poi?.coordinate.longitude
        let name = poi?.name ?? ""
        locationName = name
        if !name.isEmpty {
            let remoteCategoryID = try? expenseRepository?.latestCategoryID(forLocationName: name)
            selectedCategory = categories.category(withID: remoteCategoryID)
        }
    }

}
