//
//  AppConfiguration.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 08/10/26.
//

import Foundation

/// Values that change per build configuration (Debug/Release).
///
/// Each value comes from a build setting (e.g. `API_BASE_URL`) that is
/// exposed to the app through an Info.plist key (e.g. `APIBaseURL`).
enum AppConfiguration {
    /// Base URL of the backend API, read from the `APIBaseURL` Info.plist key.
    static let apiBaseURL: URL = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
            let url = URL(string: value)
        else {
            fatalError("APIBaseURL missing or invalid in Info.plist")
        }
        return url
    }()
}
