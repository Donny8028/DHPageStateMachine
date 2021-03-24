//
//  File.swift
//  
//
//  Created by 賢瑭 何 on 2021/3/24.
//

import Foundation

public struct DHPageStateAPIWorkerConfiguration {
    public enum PageBase {
        case zero, one
    }
    let oneTimeLoad: Bool
    let pageBase: PageBase

    public static let `default`: DHPageStateAPIWorkerConfiguration = .init(oneTimeLoad: false, pageBase: .zero)

    public init(oneTimeLoad: Bool, pageBase: DHPageStateAPIWorkerConfiguration.PageBase) {
        self.oneTimeLoad = oneTimeLoad
        self.pageBase = pageBase
    }
}
