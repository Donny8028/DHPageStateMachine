//
//  PageStateTableViewController.swift
//
//  Created by 賢瑭 何 on 2020/9/9.
//  Copyright © 2020 accuvally. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol PageStateTableViewControllerType: UITableViewContainer, UITableViewDataSource {
    var isRefreshingAnimatingPair: Bool { get set }
    var pageState: DHPageState { get }
    var pageStateMachine: DHPageStateMachineType { get }
    func pullToRefreshAnimating()
    func stopAnimating()
}

// To dodge the generic with objc protocol can't implement both.
open class TableViewController: UIViewController {
}

extension TableViewController: UITableViewDelegate {
    // Cell need to conform SkeletonLoadable
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layoutIfNeeded()
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
}
// TODO: - Need empty state view support
open class PageStateTableViewController<T: DHPageStateControllerType, U>: TableViewController, PageStateTableViewControllerType, DHPageStateObserverType where T.ViewModel == U {


    public var pageStateMachineOwner: DHPageStateMachineOwner! {
        controller as? DHPageStateMachineOwner
    }

    public var isRefreshingAnimatingPair: Bool = false

    public var pageState: DHPageState {
        pageStateMachineOwner.pageStateMachine.state
    }

    public var pageStateMachine: DHPageStateMachineType {
        pageStateMachineOwner.pageStateMachine
    }

    public let controller: T

    public var viewModel: U {
        controller.viewModel
    }

    public lazy var footerActivityIndicatorView: UIActivityIndicatorView = {
        let refresher: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            refresher = UIActivityIndicatorView(style: .medium)
        } else {
            refresher = UIActivityIndicatorView(style: .gray)
        }
        refresher.backgroundColor = UIColor.clear
        refresher.tintColor = UIColor.black
        return refresher
    }()

    public init(controller: T) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.tintColor = UIColor.black
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        return refreshControl
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupPageStateMachine()
    }

    fileprivate func setupTableView() {
        view.addSubview(tableView)
        let customBackgroundView = UIView()
        customBackgroundView.addSubview(footerActivityIndicatorView)
        customBackgroundView.frame = self.view.bounds
        tableView.backgroundView = customBackgroundView
        let footerConstraints = [
            footerActivityIndicatorView.leadingAnchor.constraint(equalTo: customBackgroundView.leadingAnchor),
            footerActivityIndicatorView.trailingAnchor.constraint(equalTo: customBackgroundView.trailingAnchor),
            footerActivityIndicatorView.bottomAnchor.constraint(equalTo: customBackgroundView.bottomAnchor),
            footerActivityIndicatorView.heightAnchor.constraint(equalToConstant: 44.0)
        ]
        let tableViewConstraints = [
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ]
        NSLayoutConstraint.activate([footerConstraints, tableViewConstraints].flatMap({$0}))
        footerActivityIndicatorView.superview?.layoutIfNeeded()
    }

    /***
        Register state machine default behavior, and can override by calling machine apply functions
     */
    public func setupPageStateMachine() {
        pageStateMachine.register(pageStateObserver: self)
        pageStateMachine.applyAnyStateWillSwitch(handler: { [weak self] _ in
            self?.emptyView(isHidden: true)
        })

        pageStateMachine.applyAnyStateDidSwitch(handler: { [weak self] state in
            self?.tableView.isScrollEnabled = !(state == .initialLoading || state == .initial)
            self?.stopAnimating()
        })

        pageStateMachine.apply(switchTo: .initialLoading, handler: { [weak self] _ in
            self?.startLoading()
        })

        pageStateMachine.apply(switchTo: .loadingMore, handler: { [weak self] _ in
            self?.footerActivityIndicatorView.startAnimating()
            self?.startLoading()
        })

        pageStateMachine.apply(switchTo: .loading, handler: { [weak self] _ in
            self?.pullToRefreshAnimating()
            self?.startLoading()
        })

        pageStateMachine.apply(switchTo: .empty, handler: { [weak self] _ in
            self?.emptyView(isHidden: false)
            self?.tableView.reloadData()
        })

        pageStateMachine.apply(switchTo: .finish, handler: { [weak self] _ in
            // For first fetch finish
            if self?.isHasMore == true {
                self?.footerActivityIndicatorView.stopAnimating()
            }
            self?.tableView.reloadData()
        })

        pageStateMachine.apply(switchTo: .noMore, handler: { [weak self] _ in
            self?.footerActivityIndicatorView.stopAnimating()
            self?.tableView.contentInset.bottom = 0
        })

        pageStateMachine.apply(switchTo: .error, handler: { [weak self] state in
            if let error = state.error {
                self?.handleStateError(error)
            }
        })
    }

    /***
        To Handle the state error, override this method.
        The default behavior is pop alert and show the parsed error.
     */
    public func handleStateError(_ error: Error) {
        let alert = UIAlertController(title: "錯誤", message: "\(error)", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "確定", style: .default, handler: nil)
        alert.addAction(confirm)
        present(alert, animated: true, completion: nil)
    }

    public func emptyView(isHidden: Bool) {
        if let subviews = tableView.backgroundView?.subviews.filter({ !($0 is UIActivityIndicatorView) }) {
            subviews.forEach({
                $0.isHidden = isHidden
            })
        }
    }

    public func startLoading() {
        controller.beginRefreshList.accept(())
    }

    @objc private func fetchData() {
        pageStateMachine.switchState(to: .loading)
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("init(coder:) has not been implemented")
    }

    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pageState == .initial || pageState == .initialLoading ? 10 : viewModel.list.count
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height >= scrollView.bounds.height else { return }
        let bottomY = scrollView.contentSize.height - scrollView.bounds.height
        let bottomInsets = max(0, (scrollView.contentOffset.y - bottomY))
        let limitBottom = min(bottomInsets, footerActivityIndicatorView.bounds.height)
        scrollView.contentInset.bottom = pageState == .noMore ? 0.0 : limitBottom
    }

    open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if pageState == .noMore { return }
        guard scrollView.contentSize.height >= scrollView.bounds.height else { return }
        let bottomY = scrollView.contentSize.height - scrollView.bounds.height
        if scrollView.contentOffset.y > bottomY && pageState != .loadingMore {
            pageStateMachine.switchState(to: .loadingMore)
        }
    }

    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        let loadableCell = cell as? CellLoadable
        if pageState == .initial || pageState == .initialLoading {
            loadableCell?.startLoading()
        } else {
            loadableCell?.stopLoading()
        }
    }
}

extension PageStateTableViewController {

    public var isHasMore: Bool {
        if pageStateMachine.state == .loading {
            return true
        }
        return viewModel.model?.isHasMore == true || viewModel.model == nil
    }

    public func pullToRefreshAnimating() {
        if tableView.contentOffset.y == -tableView.contentInset.top {
            self.isRefreshingAnimatingPair = true
            UIView.animate(withDuration: 0.1, delay: 0.1, options: .beginFromCurrentState, animations: {
                self.tableView.setContentOffset(CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height), animated: false)
            }) { _ in
                self.refreshControl.beginRefreshing()
            }
        }
    }

    public func stopAnimating() {
        if isRefreshingAnimatingPair {
            self.isRefreshingAnimatingPair = false
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: false)
             }) { _ in
                 self.refreshControl.endRefreshing()
             }
            }
            self.refreshControl.endRefreshing()
            self.tableView.contentOffset.x = -self.tableView.contentInset.top
        if pageState == .noMore {
            self.footerActivityIndicatorView.stopAnimating()
            self.tableView.contentInset.bottom = 0
        }
    }
}


extension Reactive where Base: UITableView {
    var reload: Binder<Void> {
        Binder(self.base, scheduler: MainScheduler.instance, binding: { (tableView, state) in
            tableView.reloadData()
        })
    }
}
