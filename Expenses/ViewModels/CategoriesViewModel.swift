//
//  CategoriesViewModel.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/04/26.
//

import Foundation
import Observation
import SwiftUI
import SwiftData

@Observable
class CategoriesViewModel {
    var showingForm = false
    var categoryToEdit: Category?
    let repository: any DataProvider
    var categories: [Category] = []

    init(repository: any DataProvider) {
        self.repository = repository
    }

    func rootCategories() -> [Category] {
        categories.filter { $0.parent == nil }
    }
    
    func getAll() async {
        categories = try! await repository.fetchAll() as! [Category]
    }
}
