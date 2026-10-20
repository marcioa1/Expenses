//
//  MonthFilterable.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 18/04/26.
//

import Foundation

protocol MonthFilterable: AnyObject {
    var monthFilter: MonthFilter { get }
}

extension MonthFilterable {
    var monthOffsets: [Int] { monthFilter.monthOffsets }

    /// The month chosen in `MonthCarouselView`. Months are filtered in memory from the shared
    /// basket, so changing month needs no fetch.
    var selectedMonthIndex: Int {
        get { monthFilter.selectedMonthIndex }
        set { monthFilter.selectedMonthIndex = newValue }
    }
}
