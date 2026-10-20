//
//  DailyChartView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import SwiftUI
import Charts

struct DailyChartView: View {
    @Environment(CategoryBasket.self) private var categoryBasket
    @Environment(ExpenseBasket.self) private var expenseBasket

    @State private var viewModel = DailyChartViewModel()
    @State private var showingFilter = false

    /// Called when the user taps the logout button.
    var onLogout: () -> Void = {}

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )

                switch viewModel.loadingState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    ErrorView()
                case .success:
                    chartContent
                }
            }
            .navigationTitle("Daily Spending")
            .toolbar {
                FilterToolbarItem(isActive: viewModel.filter.isActive) {
                    showingFilter = true
                }
                LogoutToolbarItem(onLogout: onLogout)
            }
            .filterSheet(
                isPresented: $showingFilter,
                filter: $viewModel.filter,
                categories: viewModel.categories
            )
        }
        .task {
            await viewModel.configure(with: categoryBasket, expenseBasket: expenseBasket)
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        Spacer()
        Section {
            Chart(viewModel.dailyTotals) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Total", item.plotTotal)
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
            .frame(height: 420)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    let food = Category(id: 1, name: "Food", icon: "fork.knife")
    let transport = Category(id: 2, name: "Transport", icon: "car.fill")
    let calendar = Calendar.current
    // A few expenses spread over the current month.
    let expenses = stride(from: 1, through: 28, by: 3).enumerated().compactMap { index, day -> Expense? in
        var comps = calendar.dateComponents([.year, .month], from: .now)
        comps.day = day
        guard let date = calendar.date(from: comps) else { return nil }
        let category = index.isMultiple(of: 2) ? food : transport
        return Expense(id: index + 1, categoryID: category.id, value: Decimal(10 + index * 7), datetime: date)
    }
    DailyChartView()
        .environment(CategoryBasket(categories: [food, transport]))
        .environment(ExpenseBasket(expenseRepository: MockExpenseDataProvider(expenses: expenses)))
}

