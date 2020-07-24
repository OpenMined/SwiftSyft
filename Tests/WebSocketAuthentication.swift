//
//  WebSocketAuthentication.swift
//  Pods
//
//  Created by Mark Jeremiah Jimenez on 12/06/2020.
//

import XCTest
import OHHTTPStubs
import Combine
@testable import SwiftSyft

class WebSocketAuthentication: XCTestCase {

    var disposeBag: Set<AnyCancellable> = Set<AnyCancellable>()

    var noAuthJob: SyftJob!
    var noAuthSendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>!
    var noAuthReceiveMessageSubject: PassthroughSubject<SignallingMessagesResponse, Never>!

    var noTokenJob: SyftJob!
    var noTokenSendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>!
    var noTokenReceiveMessageSubject: PassthroughSubject<SignallingMessagesResponse, Never>!

    var invalidTokenJob: SyftJob!
    var invalidTokenSendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>!
    var invalidTokenReceiveMessageSubject: PassthroughSubject<SignallingMessagesResponse, Never>!

    var validTokenJob: SyftJob!
    var validTokenSendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>!
    var validTokenReceiveMessageSubject: PassthroughSubject<SignallingMessagesResponse, Never>!

    override func setUp() {

        stub(condition: isHost("test.com") && isPath("/model_centric/speed-test")) { request -> HTTPStubsResponse in

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

    }

    func testNoAuth() {

        let url = URL(string: "ws://test.com:5000")!

        self.noAuthSendMessageSubject = PassthroughSubject<SignallingMessagesRequest, Never>()
        self.noAuthReceiveMessageSubject = PassthroughSubject<SignallingMessagesResponse, Never>()
        let receiveMessagePublisher = self.noAuthReceiveMessageSubject.eraseToAnyPublisher()

        self.noAuthJob = SyftJob(connectionType: .socket(url: url, sendMessageSubject: self.noAuthSendMessageSubject, receiveMessagePublisher: receiveMessagePublisher), modelName: "MNIST", version: "1.0")

        let authSuccessfulExpectation = expectation(description: "No auth successful expectation")

        self.noAuthSendMessageSubject.sink(receiveCompletion: { _ in }) { messageRequest in
            switch messageRequest {
            case .authRequest(authToken: _):

                self.noAuthReceiveMessageSubject.send(.authRequestResponse(.success("worker-id")))

            case .cycleRequest(_):

                authSuccessfulExpectation.fulfill()

            default:
                break
            }
        }.store(in: &disposeBag)

        self.noAuthJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [authSuccessfulExpectation], timeout: 7)

    }

    func testWithAuthNoToken() {

        let url = URL(string: "ws://test.com:5000")!

        self.noTokenSendMessageSubject = PassthroughSubject<SignallingMessagesRequest, Never>()
        self.noTokenReceiveMessageSubject = PassthroughSubject<SignallingMessagesResponse, Never>()
        let receiveMessagePublisher = self.noTokenReceiveMessageSubject.eraseToAnyPublisher()

        self.noTokenJob = SyftJob(connectionType: .socket(url: url, sendMessageSubject: self.noTokenSendMessageSubject, receiveMessagePublisher: receiveMessagePublisher), modelName: "MNIST", version: "1.0")

        let authFailedExpectation = expectation(description: "No token failed expectation")

        self.noTokenSendMessageSubject.sink(receiveCompletion: { _ in }) { messageRequest in
            switch messageRequest {
            case .authRequest(let authToken, let modelName, let modelVersion):

                if authToken == nil {
                    self.noTokenReceiveMessageSubject.send(.authRequestResponse(.failure(SyftClientError(message: "Invalid token"))))
                }

            default:
                break
            }
        }.store(in: &disposeBag)

        self.noTokenJob.onError { _ in
            authFailedExpectation.fulfill()
        }

        self.noTokenJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [authFailedExpectation], timeout: 7)

    }

    func testWithInvalidToken() {

        let url = URL(string: "ws://test.com:5000")!

        self.invalidTokenSendMessageSubject = PassthroughSubject<SignallingMessagesRequest, Never>()
        self.invalidTokenReceiveMessageSubject = PassthroughSubject<SignallingMessagesResponse, Never>()
        let receiveMessagePublisher = self.invalidTokenReceiveMessageSubject.eraseToAnyPublisher()

        self.invalidTokenJob = SyftJob(connectionType: .socket(url: url, sendMessageSubject: self.invalidTokenSendMessageSubject, receiveMessagePublisher: receiveMessagePublisher), modelName: "MNIST", version: "1.0")
        self.invalidTokenJob.authToken = "invalid-token"

        let authFailedExpectation = expectation(description: "Invalid token failed expectation")

        self.invalidTokenSendMessageSubject.sink(receiveCompletion: { _ in }) { messageRequest in
            switch messageRequest {
            case .authRequest(let authToken, let modelName, let modelVersion):

                if authToken == "invalid-token" {
                    self.invalidTokenReceiveMessageSubject.send(.authRequestResponse(.failure(SyftClientError(message: "Invalid token"))))
                }

            default:
                break
            }
        }.store(in: &disposeBag)

        self.invalidTokenJob.onError { _ in
            authFailedExpectation.fulfill()
        }

        self.invalidTokenJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [authFailedExpectation], timeout: 7)

    }

    func testWithValidToken() {

        let url = URL(string: "ws://test.com:5000")!

        self.validTokenSendMessageSubject = PassthroughSubject<SignallingMessagesRequest, Never>()
        self.validTokenReceiveMessageSubject = PassthroughSubject<SignallingMessagesResponse, Never>()
        let receiveMessagePublisher = self.validTokenReceiveMessageSubject.eraseToAnyPublisher()

        self.validTokenJob = SyftJob(connectionType: .socket(url: url, sendMessageSubject: self.validTokenSendMessageSubject, receiveMessagePublisher: receiveMessagePublisher), modelName: "MNIST", version: "1.0")
        self.validTokenJob.authToken = "valid-token"

        let authSuccessfulExpectation = expectation(description: "Valid token successful expectation")

        self.validTokenSendMessageSubject.sink(receiveCompletion: { _ in }) { messageRequest in
            switch messageRequest {
            case .authRequest(let authToken, _, _):

                if authToken == "valid-token" {
                    self.validTokenReceiveMessageSubject.send(.authRequestResponse(.success("worker-id")))
                }

            case .cycleRequest(_):

                authSuccessfulExpectation.fulfill()

            default:
                break
            }
        }.store(in: &disposeBag)

        self.validTokenJob.start(chargeDetection: false, wifiDetection: false)

        wait(for: [authSuccessfulExpectation], timeout: 7)

    }


    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        HTTPStubs.removeAllStubs()

    }


}
