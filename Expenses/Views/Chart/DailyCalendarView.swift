//
//  DailyCalendarView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 20/10/26.
//

import SwiftUI

/// The selected month as a calendar, with each day's total and a color that deepens on heavier days.
struct DailyCalendarView: View {
    let month: CalendarMonth
    /// Called when the user taps a day that has expenses.
    var onSelectDay: (DailyTotal) -> Void = { _ in }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // In its own grid, so the header stays in place while the days scroll.
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(month.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 4)

            ScrollView {
                // A lazy grid identifies all its cells together, so the blanks get negative IDs
                // that can't clash with the day numbers (1...31) and hide those days.
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(-month.leadingBlankDays..<0, id: \.self) { _ in
                        Color.clear
                    }
                    ForEach(month.days) { day in
                        cell(for: day)
                    }
                }
                .padding([.horizontal, .bottom])
            }
        }
    }

    @ViewBuilder
    private func cell(for day: DailyTotal) -> some View {
        let intensity = month.intensity(of: day.total)
        let hasSpending = day.total > 0
        let isToday = day.day == month.today

        Button {
            onSelectDay(day)
        } label: {
            VStack(spacing: 2) {
                Text(day.day, format: .number)
                    .font(.caption.weight(isToday ? .bold : .regular))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                if hasSpending {
                    Text(day.total, format: .currency(code: CurrencyHelper.code).precision(.fractionLength(0)))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .aspectRatio(0.8, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hasSpending ? Color.orange.opacity(0.15 + intensity * 0.65) : Color(.systemFill))
            )
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.orange, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!hasSpending)
        .accessibilityElement(children: .combine)
    }
}

/// The expenses of one day, shown when a calendar day is tapped.
struct DayExpensesView: View {
    let date: Date?
    let expenses: [Expense]
    let category: (Expense) -> Category?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses) { expense in
                    ExpenseRowView(expense: expense, category: category(expense))
                }
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView("No Expenses", systemImage: "calendar")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Two-line title: the date, with the day's total underneath.
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(date?.formatted(.dateTime.weekday(.wide).day().month(.wide)) ?? "")
                            .font(.headline)
                        Text(expenses.reduce(Decimal.zero) { $0 + $1.value }, format: .currency(code: CurrencyHelper.code))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    let days = (1...31).map { DailyTotal(day: $0, total: $0.isMultiple(of: 3) ? Decimal($0 * 11) : 0) }
    DailyCalendarView(
        month: CalendarMonth(
            days: days,
            leadingBlankDays: 3,
            weekdaySymbols: Calendar.current.shortStandaloneWeekdaySymbols,
            today: 20
        )
    )
}
