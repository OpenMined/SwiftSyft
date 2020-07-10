import Foundation
import XCTest
import Combine
@testable import SwiftSyft

class PingCheckerTests: XCTestCase {
    
    private  let KnownHost = "openmined.org"
    private  let UnknownHost = "openmined.orgorg"
    private  let IPHost = "104.198.14.52"
    
    override func setUp() {
        super.setUp()
    }
    
    func testPingWithAKnownHost() {
    
        let expectation = XCTestExpectation(description: "Running test with \(KnownHost)")
        PingChecker.pingHostname(hostname: KnownHost, resultCallback: {latency in
            
            guard let latencyMS = latency else { return }
            XCTAssertTrue(latencyMS > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPingWithNonExistingHost() {

       let expectation = XCTestExpectation(description: "Running test with \(UnknownHost)")
       PingChecker.pingHostname(hostname: UnknownHost, resultCallback: {latency in
           XCTAssertNil(latency)
           expectation.fulfill()
           
       })
       wait(for: [expectation], timeout: 5.0)
        
      
    }
    
    func testPingWithIPHost(){
        
        let expectation = XCTestExpectation(description: "Running test with \(IPHost)")
        PingChecker.pingHostname(hostname: IPHost, resultCallback: { latency in
      
            guard let latencyMS = latency else { return }
            XCTAssertTrue(latencyMS > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 7.0)
    }
    
    func testPingFutureWithUnknownHost(){
        let expectation = XCTestExpectation(description: "Running test with \(UnknownHost)")
        let pingFuture = PingChecker.pingHostname(hostname: UnknownHost)
        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
        let cInstance = pingFuture.sink(receiveCompletion: {completion in
            switch completion {
            case .failure(let error):
                
                // Check if the error is of the right type
                XCTAssertTrue(error is PingChecker.PingCheckerError)
                // Check if the error has the correct value
                XCTAssertEqual(error as? PingChecker.PingCheckerError, PingChecker.PingCheckerError.networkUnreachable)
                expectation.fulfill()
            case .finished: ()
               }
            
        }, receiveValue: { _ in })
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPingFutureWithKnownHost() {
        let expectation = XCTestExpectation(description: "Running test with \(KnownHost)")
        let pingFuture = PingChecker.pingHostname(hostname: KnownHost)
        // cInstance is not used but according to the documentation: Deallocation of the result will tear down the subscription stream.
        let cInstance = pingFuture.sink(receiveCompletion: {_ in }, receiveValue: {
            latency in
            XCTAssertTrue(latency > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
    }
}
