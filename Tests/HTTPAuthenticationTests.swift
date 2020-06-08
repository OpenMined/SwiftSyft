//
//  AuthenticationTests.swift
//  SwiftSyft-Unit-Tests
//
//  Created by Mark Jeremiah Jimenez on 08/06/2020.
//

import XCTest
@testable import SwiftSyft
import OHHTTPStubs

class HTTPAuthenticationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        stub(condition: isHost("test.com")) { request -> HTTPStubsResponse in
            
            request.url?.scheme
        }


    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
