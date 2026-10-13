//
//  ExpensesApp.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI

@main
struct ExpensesApp: App {
    
    let authService: AuthService = RemoteAuthService(baseURL: AppConfiguration.apiBaseURL)

    private let sessionStore = SessionStore()

    /// Single source of categories shared by every tab.
    @State private var categoryBasket = CategoryBasket(categoryRepository: CategoryRemoteDataProvider())
    @State private var expenseBasket = ExpenseBasket(expenseRepository: ExpenseRemoteDataProvider())

    /// `nil` until the user signs in; drives whether the login screen or the main tabs are shown.
    /// Restored from the Keychain on launch so the user stays signed in.
    @State private var session: AuthSession? = SessionStore().load()

    var body: some Scene {
        WindowGroup {
            if session == nil {
                LoginView(authService: authService) { newSession in
                    try? sessionStore.save(newSession)
                    session = newSession
                }
            } else {
                TabView {
                    Tab("Expenses", systemImage: "list.bullet") {
                        ExpensesListView(onLogout: logout)
                    }
                    Tab("Categories", systemImage: "square.grid.2x2") {
                        CategoriesView(onLogout: logout)
                    }
                    Tab("Summary", systemImage: "chart.pie.fill") {
                        SummaryView(onLogout: logout)
                    }
                    Tab("Chart", systemImage: "chart.bar.fill") {
                        DailyChartView(onLogout: logout)
                    }
                    Tab("Grid", systemImage: "tablecells") {
                        MonthlyGridView(onLogout: logout)
                    }
                }
                .tint(.orange)
                .environment(categoryBasket)
                .environment(expenseBasket)
                .task {
                    // `APIClient` posts this when an authenticated request gets a 401.
                    for await _ in NotificationCenter.default.notifications(named: .sessionExpired) {
                        endSession()
                    }
                }
            }
        }
    }

    /// Clears the local session immediately, then tells the server to revoke the token.
    /// The server call is best-effort: the user is logged out locally even if it fails.
    private func logout() {
        guard let currentSession = session else { return }
        endSession()
        Task {
            try? await authService.signOut(currentSession)
        }
    }

    /// Forgets the session and every user's data held in memory, returning to the login screen.
    /// Used directly when the server rejects the token, since signing out with it would fail too.
    private func endSession() {
        sessionStore.clear()
        session = nil
        expenseBasket.reset()
        categoryBasket.reset()
    }
}
