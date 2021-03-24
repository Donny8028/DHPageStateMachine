//
//  File.swift
//
// 
//  Created by 賢瑭 何 on 2020/9/21.
//

import Foundation

public protocol DHPageStateMachineObserverType: AnyObject {
    func applyAnyStateWillSwitch(to new: DHPageState, from old: DHPageState)
    func applyAnyStateDidSwitch(to new: DHPageState, from old: DHPageState)
}

open class DHPageStateMachine {

    private var observers: [DHPageStateMachineObserverType] = []

    public private(set) var state: DHPageState = .initial {
        willSet {
            observers.forEach({
                $0.applyAnyStateWillSwitch(to: newValue, from: state)
            })
        }
        didSet {
            observers.forEach({
                $0.applyAnyStateDidSwitch(to: state, from: oldValue)
            })
        }
    }

    private var isNoMore: Bool = false

    public var pageStateAPIWorker: DHPageStateAPIWorkerType

    public init(pageStateAPIWorker: DHPageStateAPIWorker) {
        self.pageStateAPIWorker = pageStateAPIWorker
        pageStateAPIWorker.delegate = self
    }

    public func subscribe<T: DHPageStateMachineObserverType>(_ pageStateObserver: T) {
        self.observers.append(WeakPageStateObserver(pageStateObserver))
    }

    public func unsubscribe<T: DHPageStateMachineObserverType>(_ object: T) {
        self.observers.removeAll(where: {
            ($0 as? WeakPageStateObserver<T>)?.object === object
        })
    }

    public func refresh() {
        switchState(to: .loading)
        pageStateAPIWorker.getFirstLoad()
    }

    public func startLoading() {
        switchState(to: .initialLoading)
        pageStateAPIWorker.getFirstLoad()
    }

    public func loadMore() {
        guard !pageStateAPIWorker.isOneTimeLoad else {
            isNoMore = true
            switchState(to: .noMore)
            return
        }
        if isNoMore {
            switchState(to: .noMore)
            return
        }
        switchState(to: .loadingMore)
        pageStateAPIWorker.getMoreLoad()
    }

    private func switchState(to state: DHPageState) {
        if self.state == state { return }
        self.state = state
    }
}

extension DHPageStateMachine: DHPageStateAPIWorkerDelegate {
    public func firstLoadDidFinish(data: Codable & ListDataType) {
        let isEmpty: Bool = data.isEmpty
        let state = isEmpty ? DHPageState.empty : DHPageState.finish(data)
        switchState(to: state)
        isNoMore = !data.isHasMore
    }

    public func loadingMoreDidFinish(data: Codable & ListDataType) {
        // This data is not merge from old data list
        switchState(to: .finish(data))
        isNoMore = !data.isHasMore
    }

    public func firstLoadDataFails(error: Error) {
        // Check if no network
        switchState(to: .error(.wrapper(error)))
    }

    public func loadingMoreDataFails(error: Error) {
        switchState(to: .error(.wrapper(error)))
    }
}

extension DHPageStateMachine {
    // control point
    func set_has_more(_ state: Bool) {
        self.isNoMore = state
    }
}
