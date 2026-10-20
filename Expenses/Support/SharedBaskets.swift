//
//  SharedBaskets.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

/// The two app-wide baskets a data tab reads from (Expenses, Grid, Chart and Summary), with the
/// loading logic those tabs share.
struct SharedBaskets {
    let categoryBasket: CategoryBasket
    let expenseBasket: ExpenseBasket

    /// Derived from both baskets, so every tab agrees on whether the data is available.
    var loadingState: LoadingState {
        .combined(categoryBasket.loadState, expenseBasket.loadState)
    }

    /// Loads both baskets in parallel. Each basket only hits the server on its first load, and
    /// errors are reflected in its `loadState`, which `loadingState` reads.
    func loadIfNeeded() async {
        async let categories: Void? = try? categoryBasket.loadIfNeeded()
        async let expenses: Void? = try? expenseBasket.loadIfNeeded()
        _ = await (categories, expenses)
    }
}
