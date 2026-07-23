//
//  MonthCarouselView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/04/26.
//

import SwiftUI

struct MonthCarouselView: View {
    let monthOffsets: [Int]
    @Binding var selectedMonthIndex: Int

    private func monthLabel(for offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .month, value: offset, to: .now) ?? .now
        return date.formatted(.dateTime.month(.wide)).capitalized
    }

    var body: some View {
        Section {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(Array(monthOffsets.enumerated()), id: \.offset) { index, offset in
                            Text(monthLabel(for: offset))
                                .font(index == selectedMonthIndex ? .title3.bold() : .caption)
                                .foregroundStyle(index == selectedMonthIndex ? .orange : .secondary)
                                .id(index)
                                .onTapGesture {
                                    withAnimation {
                                        selectedMonthIndex = index
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    proxy.scrollTo(selectedMonthIndex, anchor: .center)
                }
                .onChange(of: selectedMonthIndex) {
                    withAnimation {
                        proxy.scrollTo(selectedMonthIndex, anchor: .center)
                    }
                }
            }
            .frame(height: 34)
            .listRowBackground(Color.clear)
        }
    }
}
