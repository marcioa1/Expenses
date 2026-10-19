//
//  MockRepositoryError.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 19/10/26.
//

#if DEBUG
import Foundation

/// Error thrown by the mock repositories when they're told to fail (`failingFetches`).
enum MockRepositoryError: Error, Equatable {
    case fetchFailed
}
#endif
