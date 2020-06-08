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

    enum AuthenticationMode {
        case noAuthentication
        case withAuthentication
    }

    var authMode: AuthenticationMode!

    var cycleRequestCalled: Bool!
    var cycleRequestExpectation: XCTestExpectation!

    var syftClient: SyftClient!
    var syftJob: SyftJob!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        stub(condition: isHost("test.com") && isPath("/federated/authenticate")) { request -> HTTPStubsResponse in

            let responseFile = OHPathForFile("authenticate-success.json", type(of: self))!

            return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/federated/speed-test")) { request -> HTTPStubsResponse in

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        stub(condition: isHost("test.com") && isPath("/federated/cycle-request")) { request -> HTTPStubsResponse in

            self.cycleRequestExpectation.fulfill();

            return HTTPStubsResponse(error: URLError.init(URLError.Code.cancelled))
        }



    }

    func testNoAuth() {

        authMode = .noAuthentication
        cycleRequestCalled = false

        self.cycleRequestExpectation = expectation(description: "test auth if successful")

        self.syftClient = SyftClient(url: URL(string: "http://test.com:5000")!)!
        self.syftJob = syftClient.newJob(modelName: "mnist", version: "1.0")
        self.syftJob.onError { _ in
            XCTFail("Syft Authentication Failed")
        }
        self.syftJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [self.cycleRequestExpectation], timeout: 5)

    }

    func test_with_auth_no_token() {

    }

    func test_with_auth_invalid_token() {

    }

    func test_with_auth_valid_token() {

    }

    override func tearDown() {

        HTTPStubs.removeAllStubs()

    }

}
