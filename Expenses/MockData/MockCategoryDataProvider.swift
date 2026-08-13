//
//  MockCategoryDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 12/08/26.
//

#if DEBUG
import Foundation

@MainActor
final class MockCategoryDataProvider: DataProvider {
    typealias Item = Category

    private let categories: [Category]

    init() {
        self.categories = [
            Category(name: "Food", categoryIcon: "fork.knife"),
            Category(name: "Transport", categoryIcon: "car.fill"),
            Category(name: "Entertainment", categoryIcon: "gamecontroller.fill"),
            Category(name: "Health", categoryIcon: "heart.fill"),
            Category(name: "Shopping", categoryIcon: "bag.fill")
        ]
    }

    init(categories: [Category]) {
        self.categories = categories
    }

    func fetchAll() async throws -> [Category] {
        categories
    }
}
#endif
