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
    @State private var selectedSort: SortOption? = nil

    /// Called when the user taps the logout button.
    var onLogout: () -> Void = {}

    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil ||
        viewModel.selectedExtra != .all
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthCarouselView(
                    monthOffsets: viewModel.monthOffsets,
                    selectedMonthIndex: $viewModel.selectedMonthIndex
                )
                Spacer()
                Section {
                    Chart(viewModel.expensesByDay(from: viewModel.expenses)) { item in
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
            .navigationTitle("Daily Spending")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilter = true
                    } label: {
                        Image(systemName: hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        onLogout()
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterView(
                    selectedSort: $selectedSort,
                    selectedExtra: $viewModel.selectedExtra,
                    selectedCategory: $viewModel.selectedCategory,
                    categories: viewModel.categories
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await viewModel.configure(with: categoryBasket, expenseBasket: expenseBasket)
        }
    }
}

