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
/// - `GET    api/categories`       → `200 { "categories": [Category] }`
/// - `POST   api/categories`       body `{ "category": CategoryDraft }` (no `id`) → `200/201 { "category": Category }` with the new `id`
/// - `PUT    api/categories/{id}`  body `{ "category": Category }` → `200 { "category": Category }`
/// - `DELETE api/categories/{id}`  → `2xx`
struct CategoryRemoteDataProvider: CategoryRepository {
    private enum Endpoint {
        static let categories = "api/categories"

        static func category(_ id: Int) -> String {
            "\(categories)/\(id)"
        }
    }

    private let client: APIClient

    /// - Parameter client: The app's shared `APIClient`, built once in `ExpensesApp`.
    init(client: APIClient) {
        self.client = client
    }

    func fetchAll() async throws -> [Category] {
        let response: CategoriesBody = try await client.get(Endpoint.categories)
        return response.categories
    }

    func create(_ draft: CategoryDraft) async throws -> Category {
        let response: CategoryBody<Category> = try await client.post(
            Endpoint.categories,
            body: CategoryBody(category: draft)
        )
        return response.category
    }

    func update(_ category: Category) async throws -> Category {
        let response: CategoryBody<Category> = try await client.put(
            Endpoint.category(category.id),
            body: CategoryBody(category: category)
        )
        return response.category
    }

    func delete(_ category: Category) async throws {
        try await client.delete(Endpoint.category(category.id))
    }
}
/// Root `category` key used by the backend in both directions: `{ "category": { ... } }`.
nonisolated fileprivate struct CategoryBody<Wrapped> {
    let category: Wrapped
}

nonisolated extension CategoryBody: Encodable where Wrapped: Encodable {}
nonisolated extension CategoryBody: Decodable where Wrapped: Decodable {}
nonisolated extension CategoryBody: Sendable where Wrapped: Sendable {}

/// Root `categories` key used by the backend for the list: `{ "categories": [ { ... } ] }`.
nonisolated fileprivate struct CategoriesBody: Decodable {
    let categories: [Category]
}

