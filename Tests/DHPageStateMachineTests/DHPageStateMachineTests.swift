import XCTest
@testable import DHPageStateMachine

class DHPageStateMachineTests: XCTestCase {
    var sut: DHPageStateMachine?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        sut = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_delegate_been_set() {
        let stateAPIServiceDummy = DHPageStateAPIServiceDummy()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceDummy, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)

        XCTAssertTrue(pageStateAPIWorker.delegate === sut, "Delegate should be state machine itself")
    }

    func test_observer_state_been_set() {
        let stateAPIServiceDummy = DHPageStateAPIServiceDummy()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceDummy, config: .default)
        let sut = DHPageStateMachineSpy(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverDummy()
        sut.subscribe(observer)

        XCTAssertNotNil(sut.observer, "Observer should be set")
    }

    func test_observer_state_been_removal() {
        let stateAPIServiceDummy = DHPageStateAPIServiceDummy()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceDummy, config: .default)
        let sut = DHPageStateMachineSpy(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverDummy()
        sut.subscribe(observer)
        sut.unsubscribe(observer)

        XCTAssertNil(sut.observer, "Observer should be nil")
    }

    func test_refresh_success() {
        let stateAPIServiceStub = DHPageStateAPIServiceSuccessStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        sut?.refresh()

        XCTAssertTrue(observer.oldState == .loading, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.finish = willSetState {
        } else {
            XCTFail("State should be finish")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_refresh_fails() {
        let stateAPIServiceStub = DHPageStateAPIServiceFailureStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        sut?.refresh()

        XCTAssertTrue(observer.oldState == .loading, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.error(let wrapperError) = willSetState {
            if case DHPageState.DHPageSateError.wrapper(let error) = wrapperError {
                XCTAssertTrue((error as NSError).code == 0, "error code should be 0")
            } else {
                XCTFail("State should be error")
            }
        } else {
            XCTFail("State should be error")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_first_load_success() {
        let stateAPIServiceStub = DHPageStateAPIServiceSuccessStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        sut?.startLoading()

        XCTAssertTrue(observer.oldState == .initialLoading, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.finish = willSetState {
        } else {
            XCTFail("State should be finish")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_first_load_fails() {
        let stateAPIServiceStub = DHPageStateAPIServiceFailureStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        sut?.startLoading()

        XCTAssertTrue(observer.oldState == .initialLoading, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.error(let wrapperError) = willSetState {
            if case DHPageState.DHPageSateError.wrapper(let error) = wrapperError {
                XCTAssertTrue((error as NSError).code == 0, "error code should be 0")
            } else {
                XCTFail("State should be error")
            }
        } else {
            XCTFail("State should be error")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_first_load_empty() {
        let stateAPIServiceStub = DHPageStateAPIServiceSuccessStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        stateAPIServiceStub.isEmpty = true

        sut?.startLoading()

        XCTAssertTrue(observer.oldState == .initialLoading, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.empty = willSetState {
        } else {
            XCTFail("State should be error")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_load_more_success() {
        let stateAPIServiceStub = DHPageStateAPIServiceSuccessStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        sut?.loadMore()

        XCTAssertTrue(observer.oldState == .loadingMore, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.finish = willSetState {
        } else {
            XCTFail("State should be error")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_load_more_fails() {
        let stateAPIServiceStub = DHPageStateAPIServiceFailureStub()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)

        sut?.loadMore()

        XCTAssertTrue(observer.oldState == .loadingMore, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.error(let wrapperError) = willSetState {
            if case DHPageState.DHPageSateError.wrapper(let error) = wrapperError {
                XCTAssertTrue((error as NSError).code == 0, "error code should be 0")
            } else {
                XCTFail("State should be error")
            }
        } else {
            XCTFail("State should be error")
        }

        guard let didSetState = observer.didChangeState else {
            XCTFail("State should be set")
            return
        }

        XCTAssertTrue(willSetState == didSetState, "State should be the same")
    }

    func test_onetime_load() {
        let stateAPIServiceDummy = DHPageStateAPIServiceDummy()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceDummy, config: .init(oneTimeLoad: true, pageBase: .zero))
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)

        sut?.loadMore()

        XCTAssertTrue(sut?.state == .noMore, "Old state should be loading")
    }

    func test_has_no_more() {
        let stateAPIServiceDummy = DHPageStateAPIServiceDummy()
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceDummy, config: .init(oneTimeLoad: false, pageBase: .zero))
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        sut?.set_has_more(true)

        sut?.loadMore()

        XCTAssertTrue(sut?.state == .noMore, "Old state should be no more")
    }

    func test_load_no_network_error() {
        let stateAPIServiceStub = DHPageStateAPIServiceFailureStub()
        stateAPIServiceStub.reachabilityError = true
        let pageStateAPIWorker = DHPageStateAPIWorker(pageStateAPIServiceType: stateAPIServiceStub, config: .default)
        sut = DHPageStateMachine(pageStateAPIWorker: pageStateAPIWorker)
        let observer = DHPageStateMachineObserverTypeSpy()
        sut?.subscribe(observer)
        sut?.reachability = false

        sut?.loadMore()

        XCTAssertTrue(observer.oldState == .loadingMore, "Old state should be loading")

        guard let willSetState = observer.willChangeState else {
            XCTFail("State should be set")
            return
        }

        if case DHPageState.error(let error) = willSetState {
            switch error {
            case .noNetwork: break
            default:
                XCTFail("Error should be noNetwork")
            }
        } else {
            XCTFail("State should be error")
        }
    }
}

extension DHPageStateMachineTests {

    class DHPageStateAPIServiceDummy: DHPageStateAPIServiceType {
        func getFirstLoad(resultHandler: @escaping ResultHandler) {
        }

        func getMoreLoad(resultHandler: @escaping ResultHandler) {
        }
    }

    class DHPageStateAPIServiceSuccessStub: DHPageStateAPIServiceType {
        var isHasMore: Bool = true
        var isEmpty: Bool = false

        func getFirstLoad(resultHandler: @escaping ResultHandler) {
            let model = PageModel(isHasMore: isHasMore, isEmpty: isEmpty)
            resultHandler(.success(model))
        }

        func getMoreLoad(resultHandler: @escaping ResultHandler) {
            let model = PageModel(isHasMore: isHasMore, isEmpty: isEmpty)
            resultHandler(.success(model))
        }
    }

    class DHPageStateAPIServiceFailureStub: DHPageStateAPIServiceType {

        var reachabilityError: Bool = false

        func getFirstLoad(resultHandler: @escaping ResultHandler) {
            let error = reachabilityError ? DHPageState.DHPageSateError.noNetwork : DHPageState.DHPageSateError.wrapper(NSError(domain: "test_error", code: 0, userInfo: nil))
            resultHandler(.failure(error))
        }

        func getMoreLoad(resultHandler: @escaping ResultHandler) {
            let error = reachabilityError ? DHPageState.DHPageSateError.noNetwork : DHPageState.DHPageSateError.wrapper(NSError(domain: "test_error", code: 0, userInfo: nil))
            resultHandler(.failure(error))
        }
    }

    class DHPageStateMachineObserverDummy: DHPageStateMachineObserverType {
        func applyAnyStateWillSwitch(to new: DHPageState, from old: DHPageState) {
        }
        func applyAnyStateDidSwitch(to new: DHPageState, from old: DHPageState) {
        }
    }

    class DHPageStateMachineObserverTypeSpy: DHPageStateMachineObserverType {
        var oldState: DHPageState?
        var willChangeState: DHPageState?
        var didChangeState: DHPageState?

        func applyAnyStateWillSwitch(to new: DHPageState, from old: DHPageState) {
            oldState = old
            willChangeState = new
        }

        func applyAnyStateDidSwitch(to new: DHPageState, from old: DHPageState) {
            oldState = old
            didChangeState = new
        }
    }

    struct PageModel: Codable, ListDataType {
        var isHasMore: Bool
        var isEmpty: Bool
    }

    class DHPageStateMachineSpy: DHPageStateMachine {

        var observer: DHPageStateMachineObserverType?

        override func subscribe<T>(_ pageStateObserver: T) where T : DHPageStateMachineObserverType {
            self.observer = pageStateObserver
        }

        override func unsubscribe<T>(_ object: T) where T : DHPageStateMachineObserverType {
            if object === observer {
                self.observer = nil
            }
        }
    }

}

