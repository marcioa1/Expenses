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
    
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Expense] {
        let predicate = #Predicate<Expense> { expense in
            expense.datetime >= startDate && expense.datetime <= endDate
        }
        let descriptor = FetchDescriptor<Expense>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.datetime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func latestCategory(forLocationName locationName: String) throws -> Category? {
        let predicate = #Predicate<Expense> { expense in
            expense.locationName == locationName
        }
        var descriptor = FetchDescriptor<Expense>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.datetime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.category
    }
}
