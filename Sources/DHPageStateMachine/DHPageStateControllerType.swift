//
//  PageStateControllerType.swift
//
//  Created by 賢瑭 何 on 2020/9/21.
//  Copyright © 2020 accuvally. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public protocol Moreable {
    var isHasMore: Bool { get set }
    var listData: [Codable] { get set }
}

public protocol DHPageStateControllerType {

    associatedtype T

    associatedtype ViewModel: DHPageStateViewModelType where ViewModel.T == T

    var beginRefreshList: PublishRelay<Void> { get }

    var viewModel: ViewModel { get }

    var noMoreObserver: Observable<DHPageState> { get }

    var loadObserver: Observable<T> { get }

    var dataObserver: Observable<DHPageState> { get }

    func getFirstLoad() -> Observable<T>

    func getMoreLoad() -> Observable<T>

}
// TODO: - Need auth check
extension DHPageStateControllerType {
    public var refresh: Observable<Void> {
        beginRefreshList
        .asObservable()
        .share()
    }
}

extension DHPageStateControllerType where Self: DHPageStateMachineOwner {

    public var load: () -> Observable<T> {
        let count = viewModel.list.count
        return count > 0 ? (pageStateMachine.state == .loading ? getFirstLoad : self.getMoreLoad) : getFirstLoad
    }

    public var isHasMore: Bool {
        if pageStateMachine.state == .loading {
            return true
        }
        return viewModel.model?.isHasMore == true || viewModel.model == nil
    }

    /***
        Subscribe it when you care the no more state
     */
    public var noMoreObserver: Observable<DHPageState> {
        refresh
        .skipWhile({ self.isHasMore })
        .map { DHPageState.noMore }
    }

    /***
        Wrapper Model change observer
     */
    public var dataObserver: Observable<DHPageState> {
        viewModel.modelRelay
        .asObservable()
        .skipUntil(beginRefreshList)
        .map { val in
            val?.listData.count == 0 ? DHPageState.empty : DHPageState.finish
        }
    }

    /***
        Subscribe it when you has to calling api layer and handle load more.
     */
    public var loadObserver: Observable<T> {
        refresh
        .filter({ self.isHasMore })
        .flatMapLatest({
            load()
                .retry(1)
                .catchError({ error in
                    let pageState = DHPageState(pageState: .error(error))
                    self.pageStateMachine.switchState(to: pageState)
                    return .empty()
                })
        })
        .map { value in
            if self.pageStateMachine.state != .loading && !viewModel.list.isEmpty {
                let dataList = value.listData
                var currentValue = value
                currentValue.listData = self.viewModel.list + dataList
                return currentValue
            }
            return value
        }
    }
}
