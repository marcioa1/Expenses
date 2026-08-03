//
//  CategoriesViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation
import SwiftData

@Observable
class CategoriesViewModel {
    var showingForm = false
    var categoryToEdit: Category?
    var categories: [Category] = []
    private var repository: (any DataProvider)?

    func configure(modelContext: ModelContext) async {
        repository = CategoryLocalDataProvider(modelContext: modelContext)
        await getAll()
    }

    func rootCategories() -> [Category] {
        categories.filter { $0.parent == nil }
    }

    private func getAll() async {
        guard let repository else { return }
        categories = (try? await repository.fetchAll() as? [Category]) ?? []
    }
}
