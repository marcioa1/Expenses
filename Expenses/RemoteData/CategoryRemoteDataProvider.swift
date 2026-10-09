//
//  CategoryRemoteDataProvider.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 09/10/26.
//

import Foundation

/// `CategoryRepository` backed by the HTTP JSON API.
///
/// Assumed contract (adjust `Endpoint` and `Category.CodingKeys` to match the real backend):
/// - `GET    api/categories`       → `200 [Category]` (flat list)
/// - `POST   api/categories`       body `Category` → `200/201 Category`
/// - `PUT    api/categories/{id}`  body `Category` → `200 Category`
/// - `DELETE api/categories/{id}`  → `2xx`
struct CategoryRemoteDataProvider: CategoryRepository {
    private enum Endpoint {
        static let categories = "api/categories"

        static func category(_ id: UUID) -> String {
            "\(categories)/\(id.uuidString.lowercased())"
        }
    }

    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func fetchAll() async throws -> [Category] {
        let categories: [Category] = try await client.get(Endpoint.categories)
        return categories.sorted { $0.name < $1.name }
    }

    func create(_ category: Category) async throws -> Category {
        try await client.post(Endpoint.categories, body: category)
    }

    func update(_ category: Category) async throws -> Category {
        try await client.put(Endpoint.category(category.id), body: category)
    }

    func delete(_ category: Category) async throws {
        try await client.delete(Endpoint.category(category.id))
    }
}
