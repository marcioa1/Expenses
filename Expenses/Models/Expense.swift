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
    /// Server-assigned ID of the expense's `Category`; resolve it against the loaded categories.
    /// Stored as `remoteCategoryID` in earlier builds; `originalName` makes SwiftData migrate the
    /// existing column instead of dropping it. The default value lets lightweight migration fill new rows.
    @Attribute(originalName: "remoteCategoryID")
    var categoryID: Int = 0
    var details: String?
    var value: Double
    var datetime: Date
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var extraordinary: Bool = false

    init(id: UUID = UUID(), categoryID: Int, details: String? = nil, value: Double, datetime: Date = .now, latitude: Double? = nil, longitude: Double? = nil, locationName: String? = nil, extraordinary: Bool = false) {
        self.id = id
        self.categoryID = categoryID
        self.details = details
        self.value = value
        self.datetime = datetime
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.extraordinary = extraordinary
    }
}
