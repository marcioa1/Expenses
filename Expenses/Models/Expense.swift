//
//  Expense.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 30/03/26.
//

import Foundation

struct Expense: Identifiable, Codable {
    var id: Int
    var categoryID: Int = 0
    var details: String?
    /// Money is kept as `Decimal` so sums and totals have no binary floating-point rounding errors.
    var value: Decimal
    var datetime: Date
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var extraordinary: Bool = false

    init(id: Int, categoryID: Int, details: String? = nil, value: Decimal, datetime: Date = .now, latitude: Double? = nil, longitude: Double? = nil, locationName: String? = nil, extraordinary: Bool = false) {
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
    enum CodingKeys: String, CodingKey {
        case id
        case categoryID = "category_id"
        case details
        case value
        case datetime
        case latitude
        case longitude
        case locationName = "location_name"
        case extraordinary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        categoryID = try container.decode(Int.self, forKey: .categoryID)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        value = try container.decodeMoney(forKey: .value)
        datetime = try container.decode(Date.self, forKey: .datetime)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        extraordinary = try container.decodeIfPresent(Bool.self, forKey: .extraordinary) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(categoryID, forKey: .categoryID)
        // Optionals are encoded as `null` (not omitted) so an update can clear them.
        try container.encode(details, forKey: .details)
        try container.encode(value, forKey: .value)
        try container.encode(datetime, forKey: .datetime)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(extraordinary, forKey: .extraordinary)
    }
}

/// Body for creating an expense; it has no `id` because the server assigns it.
struct ExpenseDraft: Encodable, Equatable {
    var categoryID: Int
    var details: String?
    var value: Decimal
    var datetime: Date = .now
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var extraordinary: Bool = false

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case details
        case value
        case datetime
        case latitude
        case longitude
        case locationName = "location_name"
        case extraordinary
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(details, forKey: .details)
        try container.encode(value, forKey: .value)
        try container.encode(datetime, forKey: .datetime)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(extraordinary, forKey: .extraordinary)
    }
}

extension KeyedDecodingContainer {
    /// Decodes a money amount sent either as a JSON string (`"25.50"`, how many backends
    /// serialize decimal columns) or as a JSON number (`25.5`).
    /// Strings are parsed with a fixed `.` separator, independent of the device locale.
    func decodeMoney(forKey key: Key) throws -> Decimal {
        if let string = try? decode(String.self, forKey: key) {
            guard let decimal = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key, in: self, debugDescription: "Invalid decimal string: \(string)"
                )
            }
            return decimal
        }
        return try decode(Decimal.self, forKey: key)
    }
}
