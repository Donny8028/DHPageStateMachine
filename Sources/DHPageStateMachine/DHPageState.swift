//
//  File.swift
//  
//
//  Created by 賢瑭 何 on 2021/3/24.
//

import Foundation

public enum DHPageState: CustomStringConvertible, Equatable {

    public static func == (lhs: DHPageState, rhs: DHPageState) -> Bool {
        "\(lhs.description)" == "\(rhs.description)"
    }

    case initial, initialLoading, loadingMore, loading, empty, finish(Codable), noMore, error(DHPageSateError)

    public var description: String {
        var identifier = ""
        switch self {
        case .initial:
            identifier = "initial"
        case .initialLoading:
            identifier = "initialLoading"
        case .loadingMore:
            identifier = "loadingMore"
        case .loading: // User pull to refresh
            identifier = "loading"
        case .empty:
            identifier = "empty"
        case .finish:
            identifier = "finish"
        case .noMore:
            identifier = "noMore"
        case .error:
            identifier = "error"
        }
        return identifier
    }

    public enum DHPageSateError: Error {
        case wrapper(Error)
    }
}
