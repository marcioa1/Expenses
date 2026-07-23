//
//  DailyChartView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import SwiftUI
import SwiftData
import Charts

struct DailyChartView: View {
    @Query(sort: \Expense.datetime, order: .reverse) private var allExpenses: [Expense]

    @State private var viewModel = DailyChartViewModel()

    var body: some View {
        NavigationStack {
            List {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )

                Section {
                    Chart(viewModel.expensesByDay(from: allExpenses)) { item in
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("Total", item.total)
                        )
                        .foregroundStyle(.orange)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 5)) { value in
                            AxisValueLabel()
                            AxisGridLine()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                            AxisGridLine()
                        }
                    }
                    .frame(height: 250)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Daily Spending")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarTotalView(
                        totalAmount: viewModel.totalAmount(from: allExpenses)
                    )
                }
            }

        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Expense.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let food = Category(name: "Food", categoryIcon: "fork.knife")
    let transport = Category(name: "Transport", categoryIcon: "car.fill")
    context.insert(food)
    context.insert(transport)
    context.insert(Expense(category: food, details: "Lunch", value: 25.50))
    context.insert(Expense(category: food, details: "Groceries", value: 87.30))
    context.insert(Expense(category: transport, value: 12.00))
    return DailyChartView()
        .modelContainer(container)
}
