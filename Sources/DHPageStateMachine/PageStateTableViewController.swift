//
//  PageStateTableViewController.swift
//  ACCUPASS
//
//  Created by 賢瑭 何 on 2020/9/9.
//  Copyright © 2020 accuvally. All rights reserved.
//

import UIKit

protocol UITableViewContainer: class {
    var tableView: UITableView { get }
}

protocol CellLoadable {
    func startLoading()
    func stopLoading()
}

protocol PageStateTableViewControllerType: UITableViewContainer, UITableViewDataSource {
    var isRefreshingAnimatingPair: Bool { get set }
    var pageState: DHPageState { get }
    var pageStateMachine: DHPageStateMachineType { get }
    func pullToRefreshAnimating()
    func stopAnimating()
}

// To dodge the generic with objc protocol can't implement both.
class ACTableViewController: UIViewController {
}

extension ACTableViewController: UITableViewDelegate {
    // Cell need to conform SkeletonLoadable
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layoutIfNeeded()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
}
// TODO: - Need empty state view support
class PageStateTableViewController<T: DHPageStateControllerType, U>: ACTableViewController, PageStateTableViewControllerType, DHPageStateObserverType where T.ViewModel == U {


    var pageStateMachineOwner: DHPageStateMachineOwner! {
        controller as? DHPageStateMachineOwner
    }

    var isRefreshingAnimatingPair: Bool = false

    var pageState: DHPageState {
        pageStateMachineOwner.pageStateMachine.state
    }

    var pageStateMachine: DHPageStateMachineType {
        pageStateMachineOwner.pageStateMachine
    }

    let controller: T

    var viewModel: U {
        controller.viewModel
    }

    lazy var footerActivityIndicatorView: UIActivityIndicatorView = {
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

    init(controller: T) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.clear
//        refreshControl.tintColor = UIColor.init(netHex: ACConstants.Color.CisColor)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        return refreshControl
    }()

    override func viewDidLoad() {
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
    func setupPageStateMachine() {
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
    func handleStateError(_ error: Error) {
        let alert = UIAlertController(title: "錯誤", message: "\(error)", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "確定", style: .default, handler: nil)
        alert.addAction(confirm)
        present(alert, animated: true, completion: nil)
    }

    func emptyView(isHidden: Bool) {
        if let subviews = tableView.backgroundView?.subviews.filter({ !($0 is UIActivityIndicatorView) }) {
            subviews.forEach({
                $0.isHidden = isHidden
            })
        }
    }

    func startLoading() {
        controller.beginRefreshList.accept(())
    }

    @objc private func fetchData() {
        pageStateMachine.switchState(to: .loading)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pageState == .initial || pageState == .initialLoading ? 10 : viewModel.list.count
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height >= scrollView.bounds.height else { return }
        let bottomY = scrollView.contentSize.height - scrollView.bounds.height
        let bottomInsets = max(0, (scrollView.contentOffset.y - bottomY))
        let limitBottom = min(bottomInsets, footerActivityIndicatorView.bounds.height)
        scrollView.contentInset.bottom = pageState == .noMore ? 0.0 : limitBottom
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if pageState == .noMore { return }
        guard scrollView.contentSize.height >= scrollView.bounds.height else { return }
        let bottomY = scrollView.contentSize.height - scrollView.bounds.height
        if scrollView.contentOffset.y > bottomY && pageState != .loadingMore {
            pageStateMachine.switchState(to: .loadingMore)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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

    var isHasMore: Bool {
        if pageStateMachine.state == .loading {
            return true
        }
        return viewModel.model?.isHasMore == true || viewModel.model == nil
    }

    func pullToRefreshAnimating() {
        if tableView.contentOffset.y == -tableView.contentInset.top {
            self.isRefreshingAnimatingPair = true
            UIView.animate(withDuration: 0.1, delay: 0.1, options: .beginFromCurrentState, animations: {
                self.tableView.setContentOffset(CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height), animated: false)
            }) { _ in
                self.refreshControl.beginRefreshing()
            }
        }
    }

    func stopAnimating() {
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
