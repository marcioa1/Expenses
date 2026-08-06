//
//  ErrorView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 06/08/26.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        ContentUnavailableView(
            "Something went wrong",
            systemImage: "exclamationmark.triangle",
            description: Text("Please try again later.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView()
}
