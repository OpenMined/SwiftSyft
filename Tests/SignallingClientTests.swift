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

class MockSignallingClientDelegate: SignallingClientDelegate {

    var receivedMesage: SignallingMessages!
    var didCallReceivedMessage: Bool = false

    func didReceive(_ message: SignallingMessages) {
        self.didCallReceivedMessage = true
        self.receivedMesage = message
    }

}


class SignallingClientTests: XCTestCase {

    var signallingClient: SignallingClient!
    var mockSocketClient: MockSocketClient!
    var mockSignallingDelegate: MockSignallingClientDelegate!


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
        let message = SignallingMessages.joinRoom(workerId: UUID(), scopeId: UUID())
        try! self.signallingClient.send(message)

        let encoder = JSONEncoder()
        let messageData = try! encoder.encode(message)

        XCTAssertEqual(messageData, mockSocketClient.sentData)

    }

    func testDeliverMessage() {

        let message = SignallingMessages.joinRoom(workerId: UUID(), scopeId: UUID())
        let encoder = JSONEncoder()
        let messageData = try! encoder.encode(message)

        let mockSignallingDelegate = MockSignallingClientDelegate()
        self.signallingClient.delegate = mockSignallingDelegate
        self.signallingClient.didReceive(socketMessage: .success(messageData))

        XCTAssertTrue(mockSignallingDelegate.didCallReceivedMessage)
        XCTAssertEqual(message, mockSignallingDelegate.receivedMesage)

    }

    func testKeepAliveMessage() {

        self.mockSocketClient.delegate!.didConnect(self.mockSocketClient)
        MockTimer.currentTimer.fire()

        if let data = self.mockSocketClient.sentData {

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: String]
                XCTAssertEqual(json, ["type": "socket-ping"])
            } catch {
                XCTFail("Did not send valid json message")
            }

        } else {
            XCTFail("Did not send any keep alive message")
        }

    }


}
