//
//  SharedToolbarItems.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

import SwiftUI

/// Toolbar button that opens the filter sheet; its icon is filled while a filter is active.
struct FilterToolbarItem: ToolbarContent {
    let isActive: Bool
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Filters", systemImage: isActive
                   ? "line.3.horizontal.decrease.circle.fill"
                   : "line.3.horizontal.decrease.circle",
                   action: action)
        }
    }
}

/// Toolbar button that signs the user out, shown on every tab.
struct LogoutToolbarItem: ToolbarContent {
    let onLogout: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Logout", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                onLogout()
            }
        }
    }
}
