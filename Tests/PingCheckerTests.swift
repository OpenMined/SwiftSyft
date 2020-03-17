import Foundation
import XCTest
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
        PingChecker.pingHostname(hostname: KnownHost, andResultCallback: {latency in
            
            guard let latencyMS = latency else { return }
            XCTAssertTrue(latencyMS > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPingWithNonExistingHost() {

       let expectation = XCTestExpectation(description: "Running test with \(UnknownHost)")
       PingChecker.pingHostname(hostname: UnknownHost, andResultCallback: {latency in
           XCTAssertNil(latency)
           expectation.fulfill()
           
       })
       wait(for: [expectation], timeout: 5.0)
        
      
    }
    
    func testPingWithIPHost(){
        
        let expectation = XCTestExpectation(description: "Running test with \(IPHost)")
        PingChecker.pingHostname(hostname: IPHost, andResultCallback: {latency in
      
            guard let latencyMS = latency else { return }
            XCTAssertTrue(latencyMS > 0)
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
    }
}
