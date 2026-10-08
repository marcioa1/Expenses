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
            Category.self,
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

    /// `nil` until the user signs in; drives whether the login screen or the main tabs are shown.
    @State private var session: AuthSession?

    var body: some Scene {
        WindowGroup {
            if session == nil {
                LoginView(authService: authService) { newSession in
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
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
