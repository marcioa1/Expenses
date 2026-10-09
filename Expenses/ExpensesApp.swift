//
//  ExpensesApp.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 29/03/26.
//

import SwiftUI
import SwiftData

@main
struct ExpensesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    let authService: AuthService = RemoteAuthService(baseURL: AppConfiguration.apiBaseURL)

    private let sessionStore = SessionStore()

    /// Single source of categories shared by every tab.
    @State private var categoryBasket = CategoryBasket(categoryRepository: CategoryRemoteDataProvider())

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
                        ExpensesListView()
                    }
                    Tab("Categories", systemImage: "square.grid.2x2") {
                        CategoriesView()
                    }
                    Tab("Summary", systemImage: "chart.pie.fill") {
                        SummaryView()
                    }
                    Tab("Chart", systemImage: "chart.bar.fill") {
                        DailyChartView()
                    }
                    Tab("Grid", systemImage: "tablecells") {
                        MonthlyGridView()
                    }
                }
                .tint(.orange)
                .environment(categoryBasket)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
