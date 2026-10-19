//
//  ExpenseDecodingTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

import Testing
import Foundation
@testable import Expenses

@MainActor
struct ExpenseDecodingTests {

    private func decode(value: String = "10", datetime: String = "2026-10-13T10:00:00Z") throws -> Expense {
        let json = """
        {
            "id": 1,
            "category_id": 2,
            "details": null,
            "value": \(value),
            "datetime": "\(datetime)",
            "location_name": null,
            "extraordinary": false
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleISO8601
        return try decoder.decode(Expense.self, from: Data(json.utf8))
    }

    // MARK: - Dates

    /// 2026-10-13 10:00:00 UTC
    private let expectedDate = Date(timeIntervalSince1970: 1_791_885_600)

    @Test(arguments: [
        "2026-10-13T10:00:00Z",
        "2026-10-13T10:00:00",           // no timezone (naive_datetime) → UTC
        "2026-10-13T10:00:00.000000Z",   // microseconds (utc_datetime_usec)
        "2026-10-13T12:00:00+02:00"
    ])
    func decodesDateFormats(datetime: String) throws {
        let expense = try decode(datetime: datetime)
        #expect(abs(expense.datetime.timeIntervalSince(expectedDate)) < 1)
    }

    @Test func rejectsInvalidDate() {
        #expect(throws: DecodingError.self) {
            try decode(datetime: "13/10/2026")
        }
    }

    // MARK: - Money

    @Test func decodesValueSentAsString() throws {
        let expense = try decode(value: "\"87.30\"")
        #expect(expense.value == Decimal(string: "87.30"))
    }

    @Test func decodesValueSentAsNumber() throws {
        let expense = try decode(value: "1234.56")
        #expect(expense.value == Decimal(string: "1234.56"))
    }

    @Test func rejectsInvalidValueString() {
        #expect(throws: DecodingError.self) {
            try decode(value: "\"abc\"")
        }
    }

    @Test func sumsWithoutFloatingPointError() {
        // With `Double`, 0.1 + 0.2 == 0.30000000000000004.
        let total = [Decimal(string: "0.1")!, Decimal(string: "0.2")!].reduce(0, +)
        #expect(total == Decimal(string: "0.3"))
    }
}
