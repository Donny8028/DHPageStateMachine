//
//  File.swift
//
//
//  Created by 賢瑭 何 on 2020/9/21.
//

import Foundation

public typealias PageModel = Codable & ListDataType

public protocol ListDataType {
    var isHasMore: Bool { get set }
    var isEmpty: Bool { get }
}

public protocol DHPageStateAPIWorkerDelegate: class {
    func firstLoadDidFinish(data: PageModel)
    func loadingMoreDidFinish(data: PageModel)
    func firstLoadDataFails(error: Error)
    func loadingMoreDataFails(error: Error)
}

public protocol DHPageStateAPIServiceType: class {
    typealias ResultHandler = (Result<PageModel, Error>) -> Void
    func getFirstLoad(resultHandler: @escaping ResultHandler)
    func getMoreLoad(resultHandler: @escaping ResultHandler)
}

public protocol DHPageStateAPIWorkerType: class {
    func getFirstLoad()
    func getMoreLoad()
    var isOneTimeLoad: Bool { get }
}

public class DHPageStateAPIWorker: DHPageStateAPIWorkerType {

    typealias PageBase = DHPageStateAPIWorkerConfiguration.PageBase

    private var loadingMoreTime: Int = 0

    public var currentPage: Int {
        loadingMoreTime + (pageBase == .zero ? 0 : 1)
    }

    public weak var delegate: DHPageStateAPIWorkerDelegate?

    private var config: DHPageStateAPIWorkerConfiguration

    private let pageStateAPIServiceType: DHPageStateAPIServiceType

    public var isOneTimeLoad: Bool {
        config.oneTimeLoad
    }

    private var pageBase: PageBase {
        config.pageBase
    }

    public init(pageStateAPIServiceType: DHPageStateAPIServiceType, config: DHPageStateAPIWorkerConfiguration) {
        self.pageStateAPIServiceType = pageStateAPIServiceType
        self.config = config
    }

    public func getFirstLoad() {
        pageStateAPIServiceType.getFirstLoad(resultHandler: { [weak self] result in
            switch result {
            case .success(let data):
                self?.loadingMoreTime = 0
                self?.delegate?.firstLoadDidFinish(data: data)
            case .failure(let error):
                self?.delegate?.firstLoadDataFails(error: error)
            }
        })
    }

    public func getMoreLoad() {
        pageStateAPIServiceType.getMoreLoad(resultHandler: { [weak self] result in
            switch result {
            case .success(let data):
                self?.loadingMoreTime += 1
                self?.delegate?.loadingMoreDidFinish(data: data)
            case .failure(let error):
                self?.delegate?.loadingMoreDataFails(error: error)
            }
        })
    }
}
