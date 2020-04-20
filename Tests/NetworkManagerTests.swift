import Foundation
import XCTest

@testable import SwiftSyft

class NetworkManagerTests: XCTestCase {
    
    private let DummyWorkerID:String = UUID().uuidString
    private let baseUrl:String = "http://localhost"
    private let port:Int = 5000
    
    override func setUp() {
        super.setUp()
    }
    
    func testDownloadSpeed() {
        let expectation = XCTestExpectation(description: "Running download speed test")
        let networkFuture = NetworkManager(url: baseUrl, port: port).downloadSpeedTest(workerId: DummyWorkerID)
        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
        let cInstance = networkFuture.sink(receiveCompletion: {_ in }, receiveValue: {
            speed in
            XCTAssertTrue(speed > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 15.0)

    }
    
    func testUploadSpeed() {
        let expectation = XCTestExpectation(description: "Running upload speed test")
        let networkFuture = NetworkManager(url: baseUrl, port: port).uploadSpeedTest(workerId: DummyWorkerID)
        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
        let cInstance = networkFuture.sink(receiveCompletion: {_ in }, receiveValue: {
            speed in
            XCTAssertTrue(speed > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAllNetwork() {
        let expectation = XCTestExpectation(description: "Running download and upload speed test")
        let networkFuture = NetworkManager(url: baseUrl, port: port).speedTest(workerId: DummyWorkerID)
        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
        let cInstance = networkFuture.sink(receiveCompletion: {_ in }, receiveValue: {
            downloadSpeed, uploadSpeed in
            XCTAssertTrue(downloadSpeed > 0)
            XCTAssertTrue(uploadSpeed > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 15.0)                
    }
    
    
}
