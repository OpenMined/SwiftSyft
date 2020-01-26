import Foundation
import WebRTC

/// Wraps a peer connection and its data channel. Allows other observers
/// to observer peer connection and data channel events.
private class WebRTCPeer: NSObject {

    let rtcPeerConnection: RTCPeerConnection
    var rtcDataChannel: RTCDataChannel?
    var iceCandidates: [RTCIceCandidate] = []

    init(rtcPeerConnection: RTCPeerConnection) {
        self.rtcPeerConnection = rtcPeerConnection
        super.init()
        self.rtcPeerConnection.delegate = self
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

    }
}

extension WebRTCPeer: RTCDataChannelDelegate {

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {

    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
    }

}
