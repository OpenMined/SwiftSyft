import XCTest
@testable import SwiftSyft
import WebRTC

class MockWebRTCPeer: WebRTCPeer {

    var receivedAnswerCalled = false
    var receivedOfferCalled = false
    var createOfferCalled = false
    var addIceCandidateCalled = false

    init(workerId: UUID) {

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

    private let workerUUID: UUID = UUID(uuidString: "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed")!
    private let scopeUUID: UUID = UUID(uuidString: "f0be538d-e185-47cc-ac68-27ec26088ba6")!
    private let peerWorkerUUID: UUID = UUID(uuidString: "66432D2C-7057-4EC5-B62B-2DDC38517E6B")!

    override func setUp() {
        super.setUp()
    }

    func testJoinChatroomOnStart() {

        var signallingFunctionCalled = false

        let webRTCClient = WebRTCClient(workerId: workerUUID, scopeId: scopeUUID) { message in

            signallingFunctionCalled = true

            switch message {
            case .joinRoom(let workerIdToTest, let scopeIdToTest):
                XCTAssertEqual(workerIdToTest, self.workerUUID)
                XCTAssertEqual(scopeIdToTest, self.scopeUUID)
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

        let webRTCClient = WebRTCClient(workerId: workerUUID, scopeId: scopeUUID, webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { message in

            signallingFunctionCalled = true

            switch message {
            case .webRTCInternalMessage(let webrtCInternalMessage):
                switch webrtCInternalMessage {
                case .sdpOffer(let senderUUIDToTest, let scopeUUIDToTest, let peerWorkerUUIDToTest, _):
                    XCTAssertEqual(senderUUIDToTest, self.workerUUID)
                    XCTAssertEqual(scopeUUIDToTest, self.scopeUUID)
                    XCTAssertEqual(peerWorkerUUIDToTest, self.peerWorkerUUID)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        })

        webRTCClient.received(.joinRoom(workerId: self.peerWorkerUUID, scopeId: scopeUUID))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.createOfferCalled)

    }

    func testOfferReceived() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!

        let webRTCClient = WebRTCClient(workerId: self.workerUUID, scopeId: self.scopeUUID, webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { message in

            signallingFunctionCalled = true

            switch message {
            case .webRTCInternalMessage(let webrtCInternalMessage):
                switch webrtCInternalMessage {
                case .sdpAnswer(let senderUUIDToTest, let scopeUUIDToTest, let peerWorkerUUIDToTest, _):
                    XCTAssertEqual(senderUUIDToTest, self.workerUUID)
                    XCTAssertEqual(scopeUUIDToTest, self.scopeUUID)
                    XCTAssertEqual(peerWorkerUUIDToTest, self.peerWorkerUUID)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        })

        webRTCClient.received(.webRTCInternalMessage(.sdpOffer(workerId: self.peerWorkerUUID,
                                                               scopeId: self.scopeUUID,
                                                               toId: self.workerUUID,
                                                               sdp: RTCSessionDescription(type: .offer, sdp: "sdp"))))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.receivedOfferCalled)

    }

    func testAnswerReceived() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!

        let webRTCClient = WebRTCClient(workerId: self.workerUUID, scopeId: self.scopeUUID, webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: self.peerWorkerUUID)
            return mockWebRTCPeer

        }, sendSignallingMessage: { _ in

            signallingFunctionCalled = true

        })

        webRTCClient.received(.joinRoom(workerId: self.peerWorkerUUID, scopeId: scopeUUID))
        webRTCClient.received(.webRTCInternalMessage(.sdpAnswer(workerId: self.peerWorkerUUID, scopeId: self.scopeUUID, toId: self.workerUUID, sdp: RTCSessionDescription(type: .answer, sdp: "sdp"))))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.receivedAnswerCalled)

    }

    func testReceivedIceCandidate() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!

        let webRTCClient = WebRTCClient(workerId: self.workerUUID, scopeId: self.scopeUUID, webRTCPeerFactory: { workerId, _, _ in

            mockWebRTCPeer = MockWebRTCPeer(workerId: workerId)
            return mockWebRTCPeer

        }, sendSignallingMessage: { _ in

            signallingFunctionCalled = true

        })

        webRTCClient.received(.joinRoom(workerId: self.peerWorkerUUID, scopeId: scopeUUID))
        webRTCClient.received(.webRTCInternalMessage(.iceCandidate(workerId: self.peerWorkerUUID,
                                                                   scopeId: self.scopeUUID,
                                                                   toId: self.workerUUID,
                                                                   sdp: RTCIceCandidate(sdp: "sdp", sdpMLineIndex: -1, sdpMid: nil))))

        XCTAssertTrue(signallingFunctionCalled)
        XCTAssertTrue(mockWebRTCPeer.addIceCandidateCalled)


    }

    func testLocalIceCandidateObserver() {

        var signallingFunctionCalled = false
        var mockWebRTCPeer: MockWebRTCPeer!
        var signallingMessageCount = 0

        let webRTCClient = WebRTCClient(workerId: self.workerUUID, scopeId: self.scopeUUID, webRTCPeerFactory: { workerId, _, _ in

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
            case .webRTCInternalMessage(let webRTCInternalMessage):
                switch webRTCInternalMessage {
                case .iceCandidate(let senderUUID, let scopeUUID, let receiverUUID, _):
                    XCTAssertEqual(senderUUID, self.workerUUID)
                    XCTAssertEqual(scopeUUID, self.scopeUUID)
                    XCTAssertEqual(receiverUUID, self.peerWorkerUUID)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        })

        // Create new peer first
        webRTCClient.received(.joinRoom(workerId: self.peerWorkerUUID, scopeId: scopeUUID))

        // Trigger peer local ice candidate observer
        let (rtcPeerConnection, _) = RTCPeerConnection.makeDefaultRTCConnection(withIceServers: [], shouldCreateDataChannel: false)
        mockWebRTCPeer.peerConnection(rtcPeerConnection, didGenerate: RTCIceCandidate(sdp: "sdp", sdpMLineIndex: 34, sdpMid: nil))

        XCTAssertTrue(signallingFunctionCalled)

    }


}
