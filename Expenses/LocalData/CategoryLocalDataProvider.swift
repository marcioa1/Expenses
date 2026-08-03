//
//  File.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import Foundation
import SwiftData

struct CategoryLocalDataProvider: DataProvider {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getAll() async throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    }
    
    
}
