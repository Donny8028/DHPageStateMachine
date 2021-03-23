//
//  File.swift
//
//
//  Created by 賢瑭 何 on 2020/9/21.
//

import Foundation

public final class WeakPageStateObserver<T: AnyObject> {
    weak var object: T?
    public init(_ object: T) {
        self.object = object
    }
}

extension WeakPageStateObserver: DHPageStateMachineObserverType where T: DHPageStateMachineObserverType {
    public func applyAnyStateWillSwitch(to new: DHPageState, from old: DHPageState) {
        object?.applyAnyStateWillSwitch(to: new, from: old)
    }

    public func applyAnyStateDidSwitch(to new: DHPageState, from old: DHPageState) {
        object?.applyAnyStateDidSwitch(to: new, from: old)
    }
}
