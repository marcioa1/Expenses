//
//  ExpenseDecodingTests.swift
//  ExpensesTests
//
//  Created by Marcio Aun Migueis on 13/10/26.
//

import Testing
import Foundation
@testable import Expenses

struct ExpenseDecodingTests {

    private func decode(value: String) throws -> Expense {
        let json = """
        {
            "id": 1,
            "category_id": 2,
            "details": null,
            "value": \(value),
            "datetime": "2026-10-13T10:00:00Z",
            "location_name": null,
            "extraordinary": false
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Expense.self, from: Data(json.utf8))
    }

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
