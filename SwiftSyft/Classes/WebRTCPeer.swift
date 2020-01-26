import Foundation
import WebRTC

enum WebRTCConnectionType {
    case initiator
    case receiver
}

/// Wraps a peer connection and its data channel. Allows other observers
/// to observer peer connection and data channel events.
private class WebRTCPeer: NSObject {

    let rtcPeerConnection: RTCPeerConnection
    var rtcDataChannel: RTCDataChannel? {
        didSet {
            self.rtcDataChannel?.delegate = self
        }
    }
    var iceCandidates: [RTCIceCandidate] = []
    var connectionType: WebRTCConnectionType

    init(rtcPeerConnection: RTCPeerConnection, connectionType: WebRTCConnectionType) {
        self.rtcPeerConnection = rtcPeerConnection
        self.connectionType = connectionType
        super.init()
        self.rtcPeerConnection.delegate = self

        switch connectionType {
        case .initiator:
            let dataChannelConfig = RTCDataChannelConfiguration()
            self.rtcDataChannel = self.rtcPeerConnection.dataChannel(forLabel: "dataChannel",
                                                                     configuration: dataChannelConfig)
            self.rtcDataChannel?.delegate = self
        case .receiver:
            break
        }
    }

    func add(_ remoteIceCandidate: RTCIceCandidate) {
        self.rtcPeerConnection.add(remoteIceCandidate)
        iceCandidates.append(remoteIceCandidate)
    }

}

extension WebRTCPeer: RTCPeerConnectionDelegate {

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {

    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.rtcDataChannel = dataChannel
    }
}

extension WebRTCPeer: RTCDataChannelDelegate {

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {

    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
    }

}
