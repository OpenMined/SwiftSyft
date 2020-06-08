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
    let correctToken = "correct-token"

    var noAuthFlowExpectation: XCTestExpectation!
    var validTokenExpectation: XCTestExpectation!

    // I need separate syft job and client for each test case
    var noAuthClient: SyftClient!
    var noAuthJob: SyftJob!

    var noTokenClient: SyftClient!
    var noTokenJob: SyftJob!

    var invalidTokenClient: SyftClient!
    var invalidTokenJob: SyftJob!

    var validTokenClient: SyftClient!
    var validTokenJob: SyftJob!


    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        stub(condition: isHost("test.com") && isPath("/federated/authenticate")) { request -> HTTPStubsResponse in

            switch self.authMode {
            case .noAuthentication:

                let responseFile = OHPathForFile("authenticate-success.json", type(of: self))!

                return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 200, headers: nil)
            case .withAuthentication:

                guard let bodyData = request.ohhttpStubs_httpBody,
                      let jsonDict = try? JSONSerialization.jsonObject(with: bodyData, options: .allowFragments) as? [String: String],
                      let authToken = jsonDict["auth_token"] else {

                    let responseFile = OHPathForFile("authenticate-no-token.json", type(of: self))!

                    return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 400, headers: nil)
                }

                if authToken == self.correctToken {

                    let responseFile = OHPathForFile("authenticate-success.json", type(of: self))!

                    return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 200, headers: nil)


                } else {

                    let responseFile = OHPathForFile("authenticate-invalid-token.json", type(of: self))!

                    return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 400, headers: nil)

                }

            case nil:
                return HTTPStubsResponse(data: Data(), statusCode: 400, headers: nil)
            }
        }

        stub(condition: isHost("test.com") && isPath("/federated/speed-test")) { request -> HTTPStubsResponse in

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        stub(condition: isHost("test.com") && isPath("/federated/cycle-request")) { request -> HTTPStubsResponse in

            if let noAuthFlowExpectation = self.noAuthFlowExpectation {
                noAuthFlowExpectation.fulfill()
            }

            if let validTokenExpectation = self.validTokenExpectation {
                validTokenExpectation.fulfill()
            }

            return HTTPStubsResponse(error: URLError.init(URLError.Code.cancelled))
        }



    }

    func testNoAuth() {

        authMode = .noAuthentication

        self.noAuthFlowExpectation = expectation(description: "test auth if successful")

        self.noAuthClient = SyftClient(url: URL(string: "http://test.com:5000")!)!
        self.noAuthJob = self.noAuthClient.newJob(modelName: "mnist", version: "1.0")
        self.noAuthJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [self.noAuthFlowExpectation], timeout: 7)

    }

    func testWithAuthNoToken() {

        authMode = .withAuthentication

        let authNoTokenExpectation = expectation(description: "test auth with no token")

        self.noTokenClient = SyftClient(url: URL(string: "http://test.com:5000")!)!
        self.noTokenJob = self.noTokenClient.newJob(modelName: "mnist", version: "1.0")
        self.noTokenJob.onError { _ in
            authNoTokenExpectation.fulfill()
        }
        self.noTokenJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [authNoTokenExpectation], timeout: 5)

    }

    func testWithAuthInvalidToken() {

        authMode = .withAuthentication

        let authInvalidExpectation = expectation(description: "test auth with invalid token")

        self.invalidTokenClient = SyftClient(url: URL(string: "http://test.com:5000")!,
                                           authToken: "incorrect-token")!
        self.invalidTokenJob = self.invalidTokenClient.newJob(modelName: "mnist", version: "1.0")
        self.invalidTokenJob.onError { _ in
            authInvalidExpectation.fulfill()
        }
        self.invalidTokenJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [authInvalidExpectation], timeout: 5)
    }

    func test_with_auth_valid_token() {

        authMode = .withAuthentication

        self.validTokenExpectation = expectation(description: "test auth with valid token")

        self.validTokenClient = SyftClient(url: URL(string: "http://test.com:5000")!,
                                           authToken: "correct-token")!
        self.validTokenJob = self.validTokenClient.newJob(modelName: "mnist", version: "1.0")
        self.validTokenJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [self.validTokenExpectation], timeout: 7)

    }

    override func tearDown() {

        HTTPStubs.removeAllStubs()

    }

}
