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
    @Environment(CategoryBasket.self) private var categoryBasket
    
    @State private var viewModel = DailyChartViewModel()
    @State private var showingFilter = false
    @State private var selectedSort: SortOption? = nil
    
    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil ||
        viewModel.selectedExtra != .all
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Daily Spending")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    showingFilter = true
                } label: {
                    Image(systemName: hasActiveFilters
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                    .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            MonthCarouselView(
                monthOffsets: viewModel.monthOffsets,
                selectedMonthIndex: $viewModel.selectedMonthIndex
            )
            Spacer()
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
                .frame(height: 420)
                .padding(.vertical, 8)
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
        .task {
            await viewModel.configure(categoryBasket: categoryBasket)
        }
    }
}

//#Preview {
//    let container = try! ModelContainer(for: Expense.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
//    let context = container.mainContext
//    
//    let food = Category(name: "Food", icon: "fork.knife")
//    let transport = Category(name: "Transport", icon: "car.fill")
//    let shopping = Category(name: "Shopping", icon: "bag.fill")
//    context.insert(food)
//    context.insert(transport)
//    context.insert(shopping)
//    
//    let calendar = Calendar.current
//    let today = Date.now
//    
//    func date(daysAgo: Int) -> Date {
//        calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
//    }
//    
//    let sampleExpenses: [(Category, String, Double, Int)] = [
//        (food, "Lunch", 25.50, 0,),
//        (food, "Groceries", 87.30, 2),
//        (transport, "Bus", 12.00, 2),
//        (food, "Coffee", 8.50, 4),
//        (shopping, "Books", 45.00, 5),
//        (transport, "Uber", 22.00, 6),
//        (food, "Dinner", 63.00, 7),
//        (shopping, "Clothes", 120.00, 9),
//        (food, "Breakfast", 14.00, 10),
//        (transport, "Taxi", 18.50, 12),
//        (food, "Lunch", 31.00, 14),
//        (shopping, "Electronics", 299.00, 16),
//        (food, "Snacks", 9.00, 18),
//        (transport, "Gas", 55.00, 20),
//        (food, "Groceries", 102.00, 21),
//    ]
//    
//    for (category, details, value, daysAgo, extraordinary) in sampleExpenses {
//        context.insert(Expense(category: category, details: details, value: value, datetime: date(daysAgo: daysAgo), extraordinary: extraordinary))
//    }
//    
//    return DailyChartView()
//        .modelContainer(container)
//}
