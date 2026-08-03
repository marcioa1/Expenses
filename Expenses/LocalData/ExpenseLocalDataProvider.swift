//
//  ExpenseLocalDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//


import Foundation
import SwiftData

struct ExpenseLocalDataProvider: DataProvider {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.datetime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
