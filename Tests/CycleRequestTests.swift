//
//  CycleRequestTests.swift
//  Pods
//
//  Created by Mark Jeremiah Jimenez on 14/06/2020.
//

import XCTest
import OHHTTPStubs
@testable import SwiftSyft

class CycleRequestTests: XCTestCase {

    var modelExists: Bool = false

    var cycleAcceptClient: SyftClient!
    var cycleAcceptJob: SyftJob!

    var cycleRejectClient: SyftClient!
    var cycleRejectJob: SyftJob!

    override func setUp() {

        stub(condition: isHost("test.com") && isPath("/federated/authenticate")) { request -> HTTPStubsResponse in

                let responseFile = OHPathForFile("authenticate-success.json", type(of: self))!

                return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/federated/speed-test")) { request -> HTTPStubsResponse in

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        stub(condition: isHost("test.com") && isPath("/federated/cycle-request")) { [weak self] request -> HTTPStubsResponse in

            guard let self = self else {
                return HTTPStubsResponse(error: URLError.init(URLError.Code.cancelled))
            }

            if self.modelExists {

                let responseFilePath = OHPathForFile("cycle-request.json", type(of: self))!

                return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)

            } else {
                let responseFilePath = OHPathForFile("cycle-request-rejected.json", type(of: self))!

                return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)
            }

        }

        stub(condition: isHost("test.com") && isPath("/federated/get-model")) { _ -> HTTPStubsResponse in

            let responseFilePath = OHPathForFile("model_state.proto", type(of: self))!

            return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/federated/get-plan")) { _ -> HTTPStubsResponse in

            let responseFilePath = OHPathForFile("plan.proto", type(of: self))!

            return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)

        }

    }

    func testCycleAccepted() {

        modelExists = true

        let cycleAcceptedExpectation = expectation(description: "test cycle request successful")

        self.cycleAcceptClient = SyftClient(url: URL(string: "http://test.com:5000")!)!
        self.cycleAcceptJob = self.cycleAcceptClient.newJob(modelName: "mnist", version: "1.0")

        self.cycleAcceptJob.onReady { (_, _, _) in
            cycleAcceptedExpectation.fulfill()
        }

        self.cycleAcceptJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [cycleAcceptedExpectation], timeout: 7)


    }

    func testCycleRejected() {

        modelExists = false

        let cycleRejectedExpectation = expectation(description: "test cycle request rejected")

        self.cycleRejectClient = SyftClient(url: URL(string: "http://test.com:5000")!)!
        self.cycleRejectJob = self.cycleRejectClient.newJob(modelName: "mnist", version: "1.0")

        self.cycleRejectJob.onError { _ in
            cycleRejectedExpectation.fulfill()
        }

        self.cycleRejectJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [cycleRejectedExpectation], timeout: 7)
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        HTTPStubs.removeAllStubs()

    }

}
