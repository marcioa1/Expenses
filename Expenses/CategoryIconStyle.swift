//
//  CategoryIconStyle.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import SwiftUI

struct CategoryIconStyle: ViewModifier {
    var width: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .foregroundStyle(.orange)
            .frame(width: width)
    }
}

extension View {
    func categoryIconStyle(width: CGFloat = 28) -> some View {
        modifier(CategoryIconStyle(width: width))
    }
}
