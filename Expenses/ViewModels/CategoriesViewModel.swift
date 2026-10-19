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
    var loadingState: LoadingState = .loading
    private(set) var categoryBasket: CategoryBasket?

    var categories: [Category] {
        categoryBasket?.categories ?? []
    }

    /// Loads categories once; the state is set from this call alone, so a later
    /// successful retry (e.g. coming back to the tab) clears an earlier failure.
    func configure(with categoryBasket: CategoryBasket) async {
        self.categoryBasket = categoryBasket
        do {
            try await categoryBasket.loadIfNeeded()
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }

    func rootCategories() -> [Category] {
        categories.filter { $0.parentID == nil }
    }

    /// Always re-fetches categories from the server (pull-to-refresh).
    func refresh() async {
        guard let categoryBasket else { return }
        do {
            try await categoryBasket.getAllCategories()
            loadingState = .success
        } catch {
            loadingState = .failed
        }
    }
}
