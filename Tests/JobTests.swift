//
//  JobTests.swift
//  SwiftSyft-Unit-Tests
//
//  Created by Mark Jeremiah Jimenez on 14/06/2020.
//

import XCTest
import OHHTTPStubs
@testable import SwiftSyft

class JobTests: XCTestCase {

    var oneJobClient: SyftClient!
    var oneJobJob: SyftJob!

    var multipleJobClient: SyftClient!
    var multipleJobOne: SyftJob!
    var multipleJobTwo: SyftJob!

    var diffReportClient: SyftClient!
    var diffReportJob: SyftJob!

    var diffExpectation: XCTestExpectation!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        stub(condition: isHost("test.com") && isPath("/model-centric/authenticate")) { request -> HTTPStubsResponse in

                let responseFile = OHPathForFile("authenticate-success.json", type(of: self))!

                return HTTPStubsResponse(fileAtPath: responseFile, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/model-centric/speed-test")) { request -> HTTPStubsResponse in

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        stub(condition: isHost("test.com") && isPath("/model-centric/cycle-request")) { [weak self] request -> HTTPStubsResponse in

            guard let self = self else {
                return HTTPStubsResponse(error: URLError.init(URLError.Code.cancelled))
            }

            let responseFilePath = OHPathForFile("cycle-request.json", type(of: self))!

            return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/model-centric/get-model")) { _ -> HTTPStubsResponse in

            let responseFilePath = OHPathForFile("model_state.proto", type(of: self))!

            return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/model-centric/get-plan")) { _ -> HTTPStubsResponse in

            let responseFilePath = OHPathForFile("plan.proto", type(of: self))!

            return HTTPStubsResponse(fileAtPath: responseFilePath, statusCode: 200, headers: nil)

        }

        stub(condition: isHost("test.com") && isPath("/model-centric/report")) { _ -> HTTPStubsResponse in

            self.diffExpectation.fulfill()

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)

        }


    }

    func testOneJobCompletes() {

        let jobCompletedExpectation = expectation(description: "test cycle request successful")

        self.oneJobClient = SyftClient(url: URL(string: "http://test.com:3000")!)!
        self.oneJobJob = self.oneJobClient.newJob(modelName: "mnist", version: "1.0")

        self.oneJobJob.onReady { (plan, clientConfig, _) in

            XCTAssertEqual(clientConfig.name, "mnist")
            XCTAssertEqual(clientConfig.version, "1.0.0")
            XCTAssertEqual(clientConfig.batchSize, 64)
            XCTAssertEqual(clientConfig.learningRate, 0.005)


//            let trainingData = try! TrainingData(data: Array(repeating: 0.01, count: 784), shape: [1, 784])
//            let validationData = try! ValidationData(data: [1] + Array(repeating: 0, count: 9), shape: [1, 10])

//            plan.execute(trainingData: trainingData, validationData: validationData, clientConfig: clientConfig)

            jobCompletedExpectation.fulfill()
        }

        self.oneJobJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [jobCompletedExpectation], timeout: 7)
        
    }

    func testMultipleJobCompletes() {

        let jobOneExpectation = expectation(description: "test cycle request successful")
        let jobTwoExpectation = expectation(description: "test cycle request successful")

        self.multipleJobClient = SyftClient(url: URL(string: "http://test.com:3000")!)!
        self.multipleJobOne = self.multipleJobClient.newJob(modelName: "mnist", version: "1.0")
        self.multipleJobTwo = self.multipleJobClient.newJob(modelName: "mnist", version: "1.0")

        self.multipleJobOne.onReady { (_, _, _) in

            jobOneExpectation.fulfill()
        }

        self.multipleJobTwo.onReady { (_, _, _) in
            jobTwoExpectation.fulfill()
        }

        self.multipleJobOne.start(chargeDetection: false, wifiDetection: false)
        self.multipleJobTwo.start(chargeDetection: false, wifiDetection: false)

        wait(for: [jobOneExpectation, jobTwoExpectation], timeout: 7)

    }

    // TODO: Wait for PyTorch fix to run in simulator: https://github.com/pytorch/pytorch/issues/32040
    func testModelDiffReport() {

        self.diffExpectation = XCTestExpectation(description: "Test if diff was reported")

        self.diffReportClient = SyftClient(url: URL(string: "http://test.com:3000")!)!
        self.diffReportJob = self.diffReportClient.newJob(modelName: "mnist", version: "1.0")

        self.diffReportJob.onReady { (_, _, report) in

            report(Data())

        }

        self.diffReportJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [self.diffExpectation], timeout: 7)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

}
