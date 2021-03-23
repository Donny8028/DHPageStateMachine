//
//  File.swift
//
//
//  Created by 賢瑭 何 on 2020/9/21.
//

import Foundation

public typealias PageModel = Codable & ListDataType

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

protocol DHPageStateAPIWorkerType: class {
    func getFirstLoad()
    func getMoreLoad()
    var isOneTimeLoad: Bool { get }
}

public class DHPageStateAPIWorker: DHPageStateAPIWorkerType {

    typealias PageBase = DHPageStateAPIWorkerConfiguration.PageBase

    private var loadingMoreTime: Int = 0

    var currentPage: Int {
        loadingMoreTime + (pageBase == .zero ? 0 : 1)
    }

    weak var delegate: DHPageStateAPIWorkerDelegate?

    private var config: DHPageStateAPIWorkerConfiguration

    private let pageStateAPIServiceType: DHPageStateAPIServiceType

    var isOneTimeLoad: Bool {
        config.oneTimeLoad
    }

    private var pageBase: PageBase {
        config.pageBase
    }

    public init(pageStateAPIServiceType: DHPageStateAPIServiceType, config: DHPageStateAPIWorkerConfiguration) {
        self.pageStateAPIServiceType = pageStateAPIServiceType
        self.config = config
    }

    func getFirstLoad() {
        pageStateAPIServiceType.getFirstLoad(resultHandler: { [weak self] result in
            switch result {
            case .success(let data):
                self?.delegate?.firstLoadDidFinish(data: data)
                self?.loadingMoreTime = 0
            case .failure(let error):
                self?.delegate?.firstLoadDataFails(error: error)
            }
        })
    }

    func getMoreLoad() {
        pageStateAPIServiceType.getMoreLoad(resultHandler: { [weak self] result in
            switch result {
            case .success(let data):
                self?.delegate?.loadingMoreDidFinish(data: data)
                self?.loadingMoreTime += 1
            case .failure(let error):
                self?.delegate?.loadingMoreDataFails(error: error)
            }
        })
    }
}

public protocol ListDataType {
    var isHasMore: Bool { get set }
    var isEmpty: Bool { get }
}
