//
//  CategoryRepository.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Foundation

/// Read/write access to categories (remote API, mock, etc.).
@MainActor
protocol CategoryRepository: DataProvider where Item == Category {
    /// Creates a category; the returned value carries the server-assigned `id`.
    func create(_ draft: CategoryDraft) async throws -> Category
    func update(_ category: Category) async throws -> Category
    func delete(_ category: Category) async throws
}
