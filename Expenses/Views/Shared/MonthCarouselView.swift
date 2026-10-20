//
//  MonthCarouselView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 05/04/26.
//

import SwiftUI

struct MonthCarouselView: View {
    /// Month names to show, from `MonthFilter`; the position of each one is its index.
    let labels: [String]
    @Binding var selectedMonthIndex: Int

    var body: some View {
        Section {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                            Text(label)
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
