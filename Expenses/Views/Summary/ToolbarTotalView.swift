//
//  ToolbarTotalView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import SwiftUI

struct ToolbarTotalView: View {
    let totalAmount: Double

    var body: some View {
        Text(totalAmount, format: .currency(code: CurrencyHelper.code))
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .fixedSize()
    }
}
