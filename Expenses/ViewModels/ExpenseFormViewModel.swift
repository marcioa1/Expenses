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

@Observable
class ExpenseFormViewModel {
    var selectedCategory: Category?
    var details: String = ""
    var value: Double?
    var datetime: Date = .now
    var categories: [Category] = []
    var locationName: String = ""
    var latitude: Double?
    var longitude: Double?
    var extraordinary: Bool = false

    let expense: Expense?
    private var repository: (any DataProvider)?
    private var expenseRepository: ExpenseLocalDataProvider?
    private let locationManager = LocationManager()

    var isEditing: Bool { expense != nil }

    var canSave: Bool {
        selectedCategory != nil && value != nil && value! > 0
    }

    func configure(modelContext: ModelContext) async {
        repository = CategoryLocalDataProvider(modelContext: modelContext)
        expenseRepository = ExpenseLocalDataProvider(modelContext: modelContext)
        await fetchCategories()
        if !isEditing {
            await resolveLocation()
        }
    }

    func configure(with repository: any DataProvider) async {
        self.repository = repository
        await fetchCategories()
    }

    func leafCategories() -> [Category] {
        categories.filter { $0.subcategories.isEmpty }
    }

    init(expense: Expense? = nil) {
        self.expense = expense
        if let expense {
            self.selectedCategory = expense.category
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
            expense.category = selectedCategory
            expense.details = trimmedDetails.isEmpty ? nil : trimmedDetails
            expense.value = value
            expense.datetime = datetime
            expense.locationName = trimmedLocation.isEmpty ? nil : trimmedLocation
            expense.latitude = latitude
            expense.longitude = longitude
            expense.extraordinary = extraordinary
        } else {
            let newExpense = Expense(
                category: selectedCategory,
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
            selectedCategory = try? expenseRepository?.latestCategory(forLocationName: name)
        }
    }

    private func fetchCategories() async {
        guard let repository else { return }
        let fetched = (try? await repository.fetchAll() as? [Category]) ?? []
        categories = fetched.sorted { $0.name < $1.name }
    }
}
