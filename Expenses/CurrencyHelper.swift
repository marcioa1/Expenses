//
//  CurrencyHelper.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import Foundation

enum CurrencyHelper {
    static var code: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
