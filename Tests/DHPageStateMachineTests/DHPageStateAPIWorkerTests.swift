//
//
//  
//
//  Created by 賢瑭 何 on 2021/3/24.
//

import XCTest
@testable import DHPageStateMachine

class DHPageStateAPIWorkerTests: XCTestCase {

    var sut: DHPageStateAPIWorker?


    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        sut = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_zero_base_current_page_count() {
        let apiServiceType = DHPageStateAPIServiceDummy()
        sut = DHPageStateAPIWorker(pageStateAPIServiceType: apiServiceType, config: .init(oneTimeLoad: false, pageBase: .zero))

        XCTAssertEqual(sut?.currentPage, 0)
    }

    func test_one_base_current_page_count() {
        let apiServiceType = DHPageStateAPIServiceDummy()
        sut = DHPageStateAPIWorker(pageStateAPIServiceType: apiServiceType, config: .init(oneTimeLoad: false, pageBase: .one))

        XCTAssertEqual(sut?.currentPage, 1)
    }

    func test_loading_time() {
        let apiServiceType = DHPageStateAPIServiceStub()
        sut = DHPageStateAPIWorker(pageStateAPIServiceType: apiServiceType, config: .init(oneTimeLoad: false, pageBase: .zero))

        XCTAssertEqual(sut?.currentPage, 0)

        sut?.getMoreLoad()

        XCTAssertEqual(sut?.currentPage, 1)

        sut?.getFirstLoad()

        XCTAssertEqual(sut?.currentPage, 0)
    }
}

extension DHPageStateAPIWorkerTests {
    class DHPageStateAPIServiceDummy: DHPageStateAPIServiceType {
        func getFirstLoad(resultHandler: @escaping ResultHandler) {
        }

        func getMoreLoad(resultHandler: @escaping ResultHandler) {
        }
    }

    class DHPageStateAPIServiceStub: DHPageStateAPIServiceType {
        func getFirstLoad(resultHandler: @escaping ResultHandler) {
            let model = PageModel(isHasMore: true, isEmpty: false)
            resultHandler(.success(model))
        }

        func getMoreLoad(resultHandler: @escaping ResultHandler) {
            let model = PageModel(isHasMore: true, isEmpty: false)
            resultHandler(.success(model))
        }
    }

    struct PageModel: Codable, ListDataType {
        var isHasMore: Bool
        var isEmpty: Bool
    }
}
