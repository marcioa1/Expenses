//
//  CategoriesViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation

@MainActor
@Observable
class CategoriesViewModel {
    var showingForm = false
    var categoryToEdit: Category?
    private(set) var categoryBasket: CategoryBasket?

    var categories: [Category] {
        categoryBasket?.categories ?? []
    }

    func configure(with categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        try? await categoryBasket.loadIfNeeded()
    }

    func rootCategories() -> [Category] {
        categories.filter { $0.parentID == nil }
    }

    func refresh() async {
        try? await categoryBasket?.getAllCategories()
    }
}
