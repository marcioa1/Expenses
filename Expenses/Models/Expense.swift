//
//  Expense.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID = UUID()
    var category: Category
    var details: String?
    var value: Double
    var datetime: Date

    init(id: UUID = UUID(), category: Category, details: String? = nil, value: Double, datetime: Date = .now) {
        self.id = id
        self.category = category
        self.details = details
        self.value = value
        self.datetime = datetime
    }
}
