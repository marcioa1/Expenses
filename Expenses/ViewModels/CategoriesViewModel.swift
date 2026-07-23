//
//  CategoriesViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation

@Observable
class CategoriesViewModel {
    var showingForm = false
    var categoryToEdit: Category?

    func rootCategories(from allCategories: [Category]) -> [Category] {
        allCategories.filter { $0.parent == nil }
    }
}
