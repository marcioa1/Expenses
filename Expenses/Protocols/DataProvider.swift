//
//  DataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import Foundation

@MainActor
protocol DataProvider {
    associatedtype Item: Identifiable
    func fetchAll() async throws -> [Item]
}
