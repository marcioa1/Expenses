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
    /// Message of a failed refresh, shown as an alert while the loaded categories stay on screen.
    var errorMessage: String?
    private(set) var categoryBasket: CategoryBasket?

    var categories: [Category] {
        categoryBasket?.categories ?? []
    }

    /// Derived from the shared basket, so every tab agrees on whether categories are available.
    var loadingState: LoadingState {
        categoryBasket?.loadState ?? .loading
    }

    /// Loads categories once; after a failure, calling it again (e.g. coming back to the tab) retries.
    func configure(with categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        // Errors are reflected in the basket's `loadState`, which `loadingState` reads.
        try? await categoryBasket.loadIfNeeded()
    }

    func rootCategories() -> [Category] {
        categories.filter { $0.parentID == nil }
    }

    /// Always re-fetches categories from the server (pull-to-refresh). If it fails, the categories
    /// already on screen are kept and `errorMessage` tells the user they couldn't be refreshed.
    func refresh() async {
        guard let categoryBasket else { return }
        do {
            try await categoryBasket.getAllCategories()
        } catch {
            errorMessage = String(localized: "Couldn't refresh the data. Showing the last loaded data.")
        }
    }
}
