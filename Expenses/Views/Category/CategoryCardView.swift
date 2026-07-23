//
//  CategoryCardView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI
import SwiftData

struct CategoryCardView: View {
    let category: Category

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(systemName: category.categoryIcon)
                    .font(.title)
                    .categoryIconStyle()

                Text(category.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if !category.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            .padding()
            .background(Color.secondary)

            if !category.subcategories.isEmpty {
                Text("\(category.subcategories.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .offset(x: -4, y: 4)
            }
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CategoryCardView(category: Category(name: "Food"))
        .modelContainer(for: Category.self, inMemory: true)
        .padding()
}
