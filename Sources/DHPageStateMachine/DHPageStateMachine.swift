//
//  PageStateMachine.swift
//
//  Created by 賢瑭 何 on 2020/9/1.
//  Copyright © 2020 accuvally. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// Usage: Let object which conform to PageStateObserverType & PageStateMachineOwner or separate the duty on two object at a time, and implement the machine register and apply state you want to handle. Don't forget to consider the retain cycle.

// MARK: - Observer
public protocol DHPageStateObserverType: class {
    var pageStateMachineOwner: DHPageStateMachineOwner! { get }
}

public protocol DHPageStateMachineOwner {
    var pageStateMachine: DHPageStateMachineType { get }
}

// MARK: - Oberservee
public protocol DHPageStateMachineType {
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
    public var asConcrete: DHPageStateMachine {
        self as! DHPageStateMachine
    }
}

extension DHPageStateMachineType where Self: DHPageStateMachine {
    public func open() {
        open = true
    }
    /**
        If you give and error, and the machine will switch to error state and stop receiving any state until you call open()
    */
    public func shutdown(error: Error? = nil) {
        if let err = error {
            switchState(to: DHPageState(pageState: .error(err)))
        }
        open = false
    }
}

open class DHPageStateMachine: DHPageStateMachineType {

    private var handlers: [DHPageState: StateHandler] = [:]

    public var error: Error? {
        self.state.error
    }

    public var isOpen: Bool {
        open
    }

    fileprivate var open: Bool = false

    public private(set) var state: DHPageState = .initial

    private var beforeAnyStateSwitch: StateHandler?
    private var afterAnyStateSwitch: StateHandler?

    init() {
    }

    public weak var observer: DHPageStateObserverType?

    public func register(pageStateObserver: DHPageStateObserverType) {
        self.observer = pageStateObserver
    }

    public func switchState(to state: DHPageState) {
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

    public func applyAnyStateWillSwitch(handler: @escaping StateHandler) {
        self.beforeAnyStateSwitch = nil
        self.beforeAnyStateSwitch = handler
    }

    public func apply(switchTo state: DHPageState, handler: @escaping StateHandler) {
        handlers[state] = nil
        handlers[state] = handler
    }

    public func applyAnyStateDidSwitch(handler: @escaping StateHandler) {
        self.afterAnyStateSwitch = nil
        self.afterAnyStateSwitch = handler
    }

    public func start() {
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
public struct DHPageState: CustomStringConvertible, Hashable {

    public static let initial = DHPageState(pageState: .initial)
    public static let initialLoading = DHPageState(pageState: .initialLoading)
    public static let loadingMore = DHPageState(pageState: .loadingMore)
    public static let loading = DHPageState(pageState: .loading)
    public static let empty = DHPageState(pageState: .empty)
    public static let finish = DHPageState(pageState: .finish)
    public static let noMore = DHPageState(pageState: .noMore)
    public static let error = DHPageState(pageState: .error(nil))

    public let error: Error?

    public let state: DHPageStateOption

    init(pageState: DHPageStateOption) {
        self.state = pageState
        if case .error(let error) = pageState {
            self.error = error
        } else {
            error = nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    public static func == (lhs: DHPageState, rhs: DHPageState) -> Bool {
        "\(lhs.description)" == "\(rhs.description)"
    }

    public var description: String {
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

    public enum DHPageStateOption {

        case initial, initialLoading, loadingMore, loading, empty, finish, noMore, error(Error?)
    }
}

extension DHPageStateMachine: ReactiveCompatible {

}

extension Reactive where Base: DHPageStateMachine {
    var state: Binder<DHPageState> {
        Binder(self.base, scheduler: MainScheduler.instance, binding: { (machine, state) in
            machine.switchState(to: state)
        })
    }
}
