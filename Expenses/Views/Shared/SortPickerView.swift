//
//  SortPickerView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

import SwiftUI

enum SortOption: String, CaseIterable {
    case date = "Date"
    case value = "Value"
}

struct SortPickerView: View {
    @Binding var selectedSort: SortOption

    var body: some View {
        HStack {
            Text(LocalizedStringKey("Sort by:"))
            Picker("Sort by", selection: $selectedSort) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(LocalizedStringKey(option.rawValue)).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    @Previewable @State var selectedSort: SortOption = .date

    SortPickerView(selectedSort: $selectedSort)
        .padding()
}
