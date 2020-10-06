//
//  PageStateViewModelType.swift
//
//  Created by 賢瑭 何 on 2020/9/21.
//  Copyright © 2020 accuvally. All rights reserved.
//

import Foundation
import RxRelay

public protocol DHPageStateViewModelType {
    associatedtype T: Moreable
    associatedtype U: Codable

    var modelRelay: BehaviorRelay<T?> { get }

    var model: T? { get }

    var list: [U] { get }
}

extension DHPageStateViewModelType {
    public var model: T? {
        modelRelay.value
    }
}
