//
//  PageStateMachine.swift
//  ACCUPASS
//
//  Created by 賢瑭 何 on 2020/9/1.
//  Copyright © 2020 accuvally. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// Usage: Let object which conform to PageStateObserverType & PageStateMachineOwner or separate the duty on two object at a time, and implement the machine register and apply state you want to handle. Don't forget to consider the retain cycle.

// MARK: - Observer
protocol DHPageStateObserverType: class {
    var pageStateMachineOwner: DHPageStateMachineOwner! { get }
}

protocol DHPageStateMachineOwner {
    var pageStateMachine: DHPageStateMachineType { get }
}

// MARK: - Oberservee
protocol DHPageStateMachineType {
    typealias StateHandler = (DHPageState) -> Void
    var isOpen: Bool { get }
    var state: DHPageState { get }
    var error: Error? { get }
    func register(pageStateObserver: DHPageStateObserverType)
    func switchState(to state: DHPageState)
    func apply(switchTo state: DHPageState, handler: @escaping StateHandler)
    func applyAnyStateWillSwitch(handler: @escaping StateHandler)
    func applyAnyStateDidSwitch(handler: @escaping StateHandler)
    func start()
    func open()
    func shutdown(error: Error?)
}

extension DHPageStateMachineType {
    var asConcrete: DHPageStateMachine {
        self as! DHPageStateMachine
    }
}

extension DHPageStateMachineType where Self: DHPageStateMachine {
    func open() {
        open = true
    }
    /**
        If you give and error, and the machine will switch to error state and stop receiving any state until you call open()
    */
    func shutdown(error: Error? = nil) {
        if let err = error {
            switchState(to: DHPageState(pageState: .error(err)))
        }
        open = false
    }
}

class DHPageStateMachine: DHPageStateMachineType {

    private var handlers: [DHPageState: StateHandler] = [:]

    var error: Error? {
        self.state.error
    }

    var isOpen: Bool {
        open
    }

    fileprivate var open: Bool = true

    private(set) var state: DHPageState = .initial

    private var beforeAnyStateSwitch: StateHandler?
    private var afterAnyStateSwitch: StateHandler?

    init() {
    }

    weak var observer: DHPageStateObserverType?

    func register(pageStateObserver: DHPageStateObserverType) {
        self.observer = pageStateObserver
    }

    func switchState(to state: DHPageState) {
        if open {
            DispatchQueue.main.async {
                if self.state == state { return }
                self.beforeAnyStateSwitch?(state)
                self.state = state
                self.handlers[state]?(state)
                self.afterAnyStateSwitch?(state)
            }
        }
    }

    func applyAnyStateWillSwitch(handler: @escaping StateHandler) {
        self.beforeAnyStateSwitch = nil
        self.beforeAnyStateSwitch = handler
    }

    func apply(switchTo state: DHPageState, handler: @escaping StateHandler) {
        handlers[state] = nil
        handlers[state] = handler
    }

    func applyAnyStateDidSwitch(handler: @escaping StateHandler) {
        self.afterAnyStateSwitch = nil
        self.afterAnyStateSwitch = handler
    }

    func start() {
        open = true
        switchState(to: .initialLoading)
    }
}

// Empty -> Empty values
// Loading -> Empty values
// Initial -> Empty values
// InitialLoading -> Empty values
// LoadingMore -> existing values + new values
// Error -> existing values
// Finish -> existing values
struct DHPageState: CustomStringConvertible, Hashable {

    static let initial = DHPageState(pageState: .initial)
    static let initialLoading = DHPageState(pageState: .initialLoading)
    static let loadingMore = DHPageState(pageState: .loadingMore)
    static let loading = DHPageState(pageState: .loading)
    static let empty = DHPageState(pageState: .empty)
    static let finish = DHPageState(pageState: .finish)
    static let noMore = DHPageState(pageState: .noMore)
    static let error = DHPageState(pageState: .error(nil))

    let error: Error?

    let state: DHPageStateOption

    init(pageState: DHPageStateOption) {
        self.state = pageState
        if case .error(let error) = pageState {
            self.error = error
        } else {
            error = nil
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    static func == (lhs: DHPageState, rhs: DHPageState) -> Bool {
        "\(lhs.description)" == "\(rhs.description)"
    }

    var description: String {
        var identifier = ""
        switch state {
        case .initial:
            identifier = "initial"
        case .initialLoading:
            identifier = "initialLoading"
        case .loadingMore:
            identifier = "loadingMore"
        case .loading:
            identifier = "loading"
        case .empty:
            identifier = "empty"
        case .finish:
            identifier = "finish"
        case .noMore:
            identifier = "noMore"
        case .error(_):
            identifier = "error"
        }
        return identifier
    }

    enum DHPageStateOption {

        case initial, initialLoading, loadingMore, loading, empty, finish, noMore, error(Error?)
    }
}

extension DHPageStateMachine: ReactiveCompatible {

}
