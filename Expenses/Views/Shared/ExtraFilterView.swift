//
//  ExtraFilterView.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 31/08/26.
//

import SwiftUI

enum ExtraOption: String, CaseIterable {
    case all = "All"
    case extra = "Extra"
    case regular = "Regular"
}

struct ExtraFilterView: View {
    @Binding var selectedExtra: ExtraOption
    
    var body: some View {
        HStack {
            Text("Extra")
            Picker("Extra", selection: $selectedExtra) {
                ForEach(ExtraOption.allCases, id: \.self) { option in
                    Text(LocalizedStringKey(option.rawValue)).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

#Preview {
    @Previewable @State var selectedExtra: ExtraOption = .all
    ExtraFilterView(selectedExtra: $selectedExtra)
        .padding()
}
