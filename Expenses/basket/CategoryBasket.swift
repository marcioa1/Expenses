//
//  CategoryBasket.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 01/09/26.
//


final class CategoryBasket {
    private var categoryRepository: (any DataProvider)?
    var categories: [Category] = []
    
    init(categoryRepository: (any DataProvider)? = nil, categories: [Category] = []) {
        self.categoryRepository = categoryRepository
        self.categories = categories
    }
    
    func getAllCategories() async throws {
        guard let categoryRepository else { return }
        self.categories = try await categoryRepository.fetchAll() as! [Category]
    }
    
    func rootCategory(of category: Category) -> Category {
        var current = category
        while let parent = current.parent {
            current = parent
        }
        return current
    }
}
