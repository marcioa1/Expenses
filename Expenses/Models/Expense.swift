//
//  Expense.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import Foundation
import SwiftData

@Model
final class Expense: Identifiable {
    var id: UUID = UUID()
    var category: Category
    var details: String?
    var value: Double
    var datetime: Date
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var extraordinary: Bool = false

    init(id: UUID = UUID(), category: Category, details: String? = nil, value: Double, datetime: Date = .now, latitude: Double? = nil, longitude: Double? = nil, locationName: String? = nil, extraordinary: Bool = false) {
        self.id = id
        self.category = category
        self.details = details
        self.value = value
        self.datetime = datetime
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.extraordinary = extraordinary
    }
}
