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
/// - `GET    api/categories`       → `200 [{ "category": Category }]` (flat list)
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

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func fetchAll() async throws -> [Category] {
        let items: [CategoryBody<Category>] = try await client.get(Endpoint.categories)
        return items.map(\.category).sorted { $0.name < $1.name }
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
fileprivate struct CategoryBody<Wrapped> {
    let category: Wrapped
}

extension CategoryBody: Encodable where Wrapped: Encodable {}
extension CategoryBody: Decodable where Wrapped: Decodable {}

