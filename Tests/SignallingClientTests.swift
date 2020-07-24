import Foundation
import XCTest
@testable import SwiftSyft

class MockSocketClient: SocketClientProtocol {
    weak var delegate: SocketClientDelegate?

    required init(url: URL, pingInterval: Double) {

    }

    init() { }

    var didConnect: Bool = false
    var didDisconnect: Bool = false
    var sentData: Data?
    var sentText: String?

    func connect() {
        didConnect = true
    }

    func disconnect() {
        didDisconnect = true
    }

    func send(data: Data) {
        sentData = data
    }

    func sendText(text: String) {
        sentText = text
    }
}

// MockTimer from https://medium.com/@isahkaren16/testing-timer-based-features-in-swift-5ecaa4bb0c73
class MockTimer: Timer {

    var block: ((Timer) -> Void)!
    static var currentTimer: MockTimer!

    override func fire() {
        block(self)
    }

    override open class func scheduledTimer(withTimeInterval interval: TimeInterval,
                                            repeats: Bool,
                                            block: @escaping (Timer) -> Void) -> Timer {
        let mockTimer = MockTimer()
        mockTimer.block = block

        MockTimer.currentTimer = mockTimer

        return mockTimer
    }
}

class SignallingClientTests: XCTestCase {

    var signallingClient: SignallingClient!
    var mockSocketClient: MockSocketClient!

    override func setUp() {
        let url = URL(string: "http://test.com")!
        self.mockSocketClient = MockSocketClient()
        signallingClient = SignallingClient(url: url, pingInterval: 5, timerProvider: MockTimer.self, socketClientFactory: { _, _ -> SocketClientProtocol in
            return self.mockSocketClient
        })
    }

    func testConnect() {
        self.signallingClient.connect()
        XCTAssertTrue(self.mockSocketClient.didConnect)
    }

    func testDisconect() {
        self.signallingClient.disconnect()
        XCTAssertTrue(self.mockSocketClient.didDisconnect)
    }

    func testSendMessageData() {
        let message = SignallingMessagesRequest.joinRoom(workerId: UUID(), scopeId: UUID())
        self.signallingClient.send(message)

        let encoder = JSONEncoder()
        let messageData = try! encoder.encode(message)
        let messageString = String(data: messageData, encoding: .utf8)!

        XCTAssertEqual(messageString, mockSocketClient.sentText!)

    }

    func testDeliverMessage() {

        let message = SignallingMessagesResponse.joinRoom(workerId: UUID(), scopeId: UUID())
        let encoder = JSONEncoder()
        let messageData = try! encoder.encode(message)

        var didCallMessageSubscription = false
        var messageReceived: SignallingMessagesResponse?

        let subscription = self.signallingClient.incomingMessagePublisher.sink { signallingMessage in
            didCallMessageSubscription = true
            messageReceived = signallingMessage
        }
        self.signallingClient.didReceive(socketMessage: .success(messageData))
        subscription.cancel()

        XCTAssertTrue(didCallMessageSubscription)
        XCTAssertEqual(message, messageReceived)

    }

    func testKeepAliveMessage() {

        self.mockSocketClient.delegate!.didConnect(self.mockSocketClient)
        MockTimer.currentTimer.fire()

        if let text = self.mockSocketClient.sentText,
           let jsonData = text.data(using: .utf8) {

            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: String]
                XCTAssertEqual(json, ["type": "socket-ping"])
            } catch {
                XCTFail("Did not send valid json message")
            }

        } else {
            XCTFail("Did not send any keep alive message")
        }

    }


}
