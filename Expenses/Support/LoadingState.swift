//
//  LoadingState.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 03/08/26.
//

enum LoadingState {
    case loading, success, failed

    /// The state of a screen that needs several sources (e.g. categories and expenses):
    /// failed if any failed, loading if any is still loading, otherwise success.
    static func combined(_ states: LoadingState...) -> LoadingState {
        if states.contains(.failed) { return .failed }
        if states.contains(.loading) { return .loading }
        return .success
    }
}
