//
//  SyftClientTests.swift
//  OpenMinedSwiftSyft-Unit-Tests
//
//  Created by Rohith Pudari on 19/07/20.
//

import XCTest
import OHHTTPStubs
@testable import SwiftSyft

    
class SyftClientTests: XCTestCase {

    func test_init(){
        XCTAssertNotNil(SyftClient(url: URL(string: "https://www.test.com")!, authToken: "test_auth"))
        XCTAssertNotNil(SyftClient(url: URL(string: "https://www.test.com")!))
        XCTAssertNotNil(SyftClient(url: URL(string: "http://www.test.com")!, authToken: "test_auth"))
        XCTAssertNotNil(SyftClient(url: URL(string: "http://www.test.com")!))
        XCTAssertNotNil(SyftClient(url: URL(string: "ws://test.com:3000")!))
        XCTAssertNotNil(SyftClient(url:URL(string: "ws://test.com:3000")!, authToken: "test_auth"))
        XCTAssertNotNil(SyftClient(url: URL(string: "wss://test.com:3000")!))
        XCTAssertNotNil(SyftClient(url:URL(string: "wss://test.com:3000")!, authToken: "test_auth"))
    }
    func test_newjob_ws_Auth(){
        let syftClient_ws_Auth = SyftClient(url: URL(string: "ws://test.com:3000")!, authToken: "test_auth")
        XCTAssertNotNil(syftClient_ws_Auth?.newJob(modelName: "mnist", version: "1.0.0-A"))
    }
    func test_newjob_ws_NoAuth(){
        let syftClient_ws_NoAuth = SyftClient(url: URL(string: "ws://test.com:3000")!)
        XCTAssertNotNil(syftClient_ws_NoAuth?.newJob(modelName: "mn-st", version: "1.0.0.bc"))
    }
    
    func test_newjob_http_auth(){
        let syftClient_http_auth = SyftClient(url: URL(string: "http://test.com")!, authToken: "test_auth")
        XCTAssertNotNil(syftClient_http_auth?.newJob(modelName: "mnist", version: "1A"))
    }
    
    func test_newjob_http_Noauth(){
        let syftClient_http_Noauth = SyftClient(url: URL(string: "http://test.com")!)
        XCTAssertNotNil(syftClient_http_Noauth?.newJob(modelName: "1_test", version: "1.0.0-A"))
    }
    
    func test_newjob_https_auth(){
        let syftClient_https_auth = SyftClient(url: URL(string: "https://test.com")!, authToken: "test_auth")
        XCTAssertNotNil(syftClient_https_auth?.newJob(modelName: "test_model", version: "A"))
    }
    
    func test_newjob_https_Noauth(){
        let syftClient_https_Noauth = SyftClient(url: URL(string: "https://test.com")!)
            XCTAssertNotNil(syftClient_https_Noauth?.newJob(modelName: "mnist", version: "0.1"))
        }
    func test_newjob_wss_Auth(){
        let syftClient_wss_Auth = SyftClient(url: URL(string: "wss://test.com:3000")!, authToken: "test_auth")
        XCTAssertNotNil(syftClient_wss_Auth?.newJob(modelName: "mnist", version: "1.0.0-A"))
    }
    func test_newjob_wss_NoAuth(){
        let syftClient_wss_NoAuth = SyftClient(url: URL(string: "wss://test.com:3000")!)
        XCTAssertNotNil(syftClient_wss_NoAuth?.newJob(modelName: "mn-st", version: "1.0.0.bc"))
    }
    
  //  func testPerformanceExample() throws {
        // This is an example of a performance test case.
   //     self.measure {
            // Put the code you want to measure the time of here.
   //     }
  //  }

}
