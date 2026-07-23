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

    var body: some Scene {
        WindowGroup {
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
            }
            .tint(.orange)
        }
        .modelContainer(sharedModelContainer)
    }
}
