import XCTest
@testable import SwiftSyft
import WebRTC

class MockWebRTCPeer: WebRTCPeer {

    var receivedAnswerCalled = false
    var receivedOfferCalled = false
    var createOfferCalled = false
    var addIceCandidateCalled = false

    init(workerId: String) {

        // Create stub RTCPeerFunction
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: nil)
        let connectionConfig = RTCConfiguration()
        let peerConnectionFactory = RTCPeerConnectionFactory()
        let rtcPeerConnection = peerConnectionFactory.peerConnection(with: connectionConfig, constraints: constraints, delegate: nil)


        super.init(workerId: workerId, rtcPeerConnection: rtcPeerConnection, connectionType: .receiver)
    }

    override func createOffer<T>(observer: T, mediaConstraints: RTCMediaConstraints, completion: @escaping (T, RTCSessionDescription) -> Void) where T : AnyObject {
        createOfferCalled = true
        completion(observer, RTCSessionDescription(type: .offer, sdp: "123"))
    }

    override func receivedAnswer(with remoteSessionDescription: RTCSessionDescription) {
        receivedAnswerCalled = true
    }

    override func receivedOffer<T>(observer: T, with remoteSessionDescription: RTCSessionDescription, completion: @escaping (T, RTCSessionDescription) -> Void) where T : AnyObject {
        receivedOfferCalled = true
        completion(observer, RTCSessionDescription(type: .answer, sdp: "123"))
    }

    override func add(_ remoteIceCandidate: RTCIceCandidate) {
        addIceCandidateCalled = true
    }

}

class WebRTCClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func testJoinChatroomOnStart() {

        var signallingFunctionCalled = false

        let webRTCClient = WebRTCClient(workerId: "123", scopeId: "456") { message in

            signallingFunctionCalled = true

            switch message {
            case .joinRoom(let workerId, let scopeId):
                XCTAssertEqual(workerId, "123")
                XCTAssertEqual(scopeId, "456")
            default:
                XCTFail("Incorrect message sent")
            }
        }

        webRTCClient.start()

        XCTAssertTrue(signallingFunctionCalled)

    }

    func testNewPeerReceived() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!
        let testWorkerId = UUID().uuidString

        let webRTCClient = WebRTCClient(workerId: "123", scopeId: "456", webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { message in

            signallingFunctionCalled = true

            switch message {
            case .sendOffer(let senderId, let scopeId, let receiverId, _):
                XCTAssertEqual(senderId, "123")
                XCTAssertEqual(scopeId, "456")
                XCTAssertEqual(receiverId, testWorkerId)
            default:
                XCTFail()
            }
        })

        webRTCClient.received(.newPeerReceived(workerId: testWorkerId))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.createOfferCalled)

    }

    func testOfferReceived() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!
        let testWorkerId = UUID().uuidString

        let webRTCClient = WebRTCClient(workerId: "123", scopeId: "456", webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { message in

            signallingFunctionCalled = true

            switch message {
            case .sendAnswer(let senderId, let scopeId, let receiverId, _):
                XCTAssertEqual(senderId, "123")
                XCTAssertEqual(scopeId, "456")
                XCTAssertEqual(receiverId, testWorkerId)
            default:
                XCTFail()
            }
        })

        webRTCClient.received(.offerReceived(senderId: testWorkerId, remoteDescription: RTCSessionDescription(type: .offer, sdp: "sdp")))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.receivedOfferCalled)

    }

    func testAnswerReceived() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!
        let testWorkerId = UUID().uuidString

        let webRTCClient = WebRTCClient(workerId: "123", scopeId: "456", webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { _ in

            signallingFunctionCalled = true

        })

        webRTCClient.received(.newPeerReceived(workerId: testWorkerId))
        webRTCClient.received(.answerReceived(senderId: testWorkerId, remoteDescription: RTCSessionDescription(type: .answer, sdp: "sdp")))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.receivedAnswerCalled)

    }

    func testReceivedIceCandidate() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!
        let testWorkerId = UUID().uuidString

        let webRTCClient = WebRTCClient(workerId: "123", scopeId: "456", webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { _ in

            signallingFunctionCalled = true

        })

        webRTCClient.received(.newPeerReceived(workerId: testWorkerId))
        webRTCClient.received(.iceCandidateReceived(senderId: testWorkerId, iceCandidate: RTCIceCandidate(sdp: "sdp", sdpMLineIndex: 12, sdpMid: nil)))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.addIceCandidateCalled)


    }

    func testLocalIceCandidateObserver() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!
        let testWorkerId = UUID().uuidString
        var signallingMessageCount = 0

        let webRTCClient = WebRTCClient(workerId: "123", scopeId: "456", webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { message in

            // signalling function is called first for sending offer
            // second to send local ice candidate
            guard signallingMessageCount == 1 else {
                signallingMessageCount += 1
                return
            }

            signallingFunctionCalled = true

            switch message {
            case .sendIceCandidate(let senderId, let scopeId, let receiverId, _):
                XCTAssertEqual(senderId, "123")
                XCTAssertEqual(scopeId, "456")
                XCTAssertEqual(receiverId, testWorkerId)
            default:
                XCTFail()
            }
        })

        // Create new peer first
        webRTCClient.received(.newPeerReceived(workerId: testWorkerId))

        // Trigger peer local ice candidate observer
        let (rtcPeerConnection, _) = RTCPeerConnection.makeDefaultRTCConnection(withIceServers: [], shouldCreateDataChannel: false)
        mockWebRTCPeer.peerConnection(rtcPeerConnection, didGenerate: RTCIceCandidate(sdp: "sdp", sdpMLineIndex: 34, sdpMid: nil))

        XCTAssertTrue(signallingFunctionCalled)

    }


}
