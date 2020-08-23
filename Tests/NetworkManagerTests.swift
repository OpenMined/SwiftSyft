import Foundation
import XCTest

@testable import SwiftSyft

class NetworkManagerTests: XCTestCase {
    
    private let DummyWorkerID:String = UUID().uuidString
    private let baseUrl:String = "http://localhost"
    private let port:Int = 3000
    
    override func setUp() {
        super.setUp()
    }
    
    /// This is a dummy test so that this class has at least a test which can run on Github Actions.
    /// If you want to run the NetworkManager tests follow the instructions below.
    /// - Make sure that PyGrid is up and running.
    /// - Replace baseUrl and port with your base url and port.
    /// - Uncomment the tests from below.
    func testPortDummy() {
            XCTAssertTrue(port == 3000)
    }
    
//    func testDownloadSpeed() {
//        let expectation = XCTestExpectation(description: "Running download speed test")
//        let networkFuture = NetworkManager(url: baseUrl, port: port).downloadSpeedTest(workerId: DummyWorkerID)
//        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
//        let cInstance = networkFuture.sink(receiveCompletion: {_ in }, receiveValue: {
//            speed in
//            XCTAssertTrue(speed > 0)
//            expectation.fulfill()
//        })
//        wait(for: [expectation], timeout: 15.0)
//
//    }
//
//    func testUploadSpeed() {
//        let expectation = XCTestExpectation(description: "Running upload speed test")
//        let networkFuture = NetworkManager(url: baseUrl, port: port).uploadSpeedTest(workerId: DummyWorkerID)
//        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
//        let cInstance = networkFuture.sink(receiveCompletion: {_ in }, receiveValue: {
//            speed in
//            XCTAssertTrue(speed > 0)
//            expectation.fulfill()
//        })
//        wait(for: [expectation], timeout: 15.0)
//    }
//
//    func testAllNetwork() {
//        let expectation = XCTestExpectation(description: "Running download and upload speed test")
//        let networkFuture = NetworkManager(url: baseUrl, port: port).speedTest(workerId: DummyWorkerID)
//        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
//        let cInstance = networkFuture.sink(receiveCompletion: {_ in }, receiveValue: {
//            downloadSpeed, uploadSpeed in
//            XCTAssertTrue(downloadSpeed > 0)
//            XCTAssertTrue(uploadSpeed > 0)
//            expectation.fulfill()
//        })
//        wait(for: [expectation], timeout: 15.0)
//    }
    
    
}
