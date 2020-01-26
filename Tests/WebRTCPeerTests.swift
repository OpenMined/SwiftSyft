import XCTest
@testable import SwiftSyft
import WebRTC

class WebRTCPeerTests: XCTestCase {

    var webRTCPeer: WebRTCPeer!
    var rtcPeerConnection: RTCPeerConnection!
    var dataChannel: RTCDataChannel!
    
    override func setUp() {
        super.setUp()

        // Setup peer connection
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: nil)
        let connectionConfig = RTCConfiguration()
        let peerConnectionFactory = RTCPeerConnectionFactory()
        self.rtcPeerConnection = peerConnectionFactory.peerConnection(with: connectionConfig, constraints: constraints, delegate: nil)

        let channelConfig = RTCDataChannelConfiguration()
        self.dataChannel = self.rtcPeerConnection.dataChannel(forLabel: "", configuration: channelConfig)
    }
    
    func testObservingLocalIceCandidate() {

        var observerCalled = false
        var receivedIceCandidate: RTCIceCandidate?

        self.webRTCPeer = WebRTCPeer(workerId: "1234", rtcPeerConnection: self.rtcPeerConnection, connectionType: .initiator(self.dataChannel))

        self.webRTCPeer.addDiscoveredLocalIceCandidateObserver(self) { (_, _, iceCandidate) in
            observerCalled = true
            receivedIceCandidate = iceCandidate
        }

        let sentIceCandidate = RTCIceCandidate(sdp: "", sdpMLineIndex: 1, sdpMid: nil)
        self.rtcPeerConnection.delegate?.peerConnection(self.rtcPeerConnection, didGenerate: sentIceCandidate)


        XCTAssertTrue(observerCalled)
        XCTAssertEqual(receivedIceCandidate, sentIceCandidate)

    }

    func testObservingReceivingMessagesAsInitiator() {

        var observerCalled = false
        var dataReceived: Data?

        self.webRTCPeer = WebRTCPeer(workerId: "1234", rtcPeerConnection: self.rtcPeerConnection, connectionType: .initiator(self.dataChannel))

        self.webRTCPeer.addReceivedDataChannelMessageObserver(self) { (_, data) in

            observerCalled = true
            dataReceived = data
        }

        let sentData = Data()
        let buffer = RTCDataBuffer(data: sentData, isBinary: true)
        self.dataChannel.delegate?.dataChannel(self.dataChannel, didReceiveMessageWith: buffer)

        XCTAssertTrue(observerCalled)
        XCTAssertEqual(dataReceived, sentData)

    }

    func testObservingReceivingMessagesAsReceiver() {

        var observerCalled = false
        var dataReceived: Data?

        self.webRTCPeer = WebRTCPeer(workerId: "1234", rtcPeerConnection: self.rtcPeerConnection, connectionType: .receiver)

        self.webRTCPeer.addReceivedDataChannelMessageObserver(self) { (_, data) in

            observerCalled = true
            dataReceived = data
        }

        self.rtcPeerConnection.delegate?.peerConnection(self.rtcPeerConnection, didOpen: self.dataChannel)

        let sentData = Data()
        let buffer = RTCDataBuffer(data: sentData, isBinary: true)
        self.dataChannel.delegate?.dataChannel(self.dataChannel, didReceiveMessageWith: buffer)

        XCTAssertTrue(observerCalled)
        XCTAssertEqual(dataReceived, sentData)

    }


}
