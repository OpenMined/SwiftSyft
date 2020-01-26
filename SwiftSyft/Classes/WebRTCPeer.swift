import Foundation
import WebRTC

/// ObservationToken pattern to use for cancelling observers from
///  https://www.swiftbysundell.com/articles/observers-in-swift-part-2/
class ObservationToken {
    private let cancellationClosure: () -> Void

    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    func cancel() {
        cancellationClosure()
    }
}

enum WebRTCConnectionType {
    case initiator
    case receiver
}

/// Wraps a peer connection and its data channel. Allows other observers
/// to observer peer connection and data channel events.
private class WebRTCPeer: NSObject {

    let workerId: String
    let rtcPeerConnection: RTCPeerConnection
    var rtcDataChannel: RTCDataChannel? {
        didSet {
            self.rtcDataChannel?.delegate = self
        }
    }
    var iceCandidates: [RTCIceCandidate] = []
    var connectionType: WebRTCConnectionType

    private var observations = (
        discoveredLocalCandidate: [UUID: (String, RTCIceCandidate) -> Void](),
        receivedDataChannelMessage: [UUID: (Data) -> Void]()
    )

    init(workerId: String, rtcPeerConnection: RTCPeerConnection, connectionType: WebRTCConnectionType) {
        self.workerId = workerId
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

    func setRemoteDescription(_ remoteSessionDescription: RTCSessionDescription) {
        self.rtcPeerConnection.setRemoteDescription(remoteSessionDescription) { error in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        }
    }

    @discardableResult func addDiscoveredLocalIceCandidateObserver<T: AnyObject>(_ observer: T,
                                                                                 closure: @escaping (T, String, RTCIceCandidate) -> Void) -> ObservationToken {

        let observerId = UUID()

        observations.discoveredLocalCandidate[observerId] = { [weak self, weak observer] workerId, iceCandidate in

            guard let observer = observer else {
                self?.observations.discoveredLocalCandidate.removeValue(forKey: observerId)
                return
            }

            closure(observer, workerId, iceCandidate)

        }

        return ObservationToken { [weak self] in
            self?.observations.discoveredLocalCandidate.removeValue(forKey: observerId)
        }
    }

    @discardableResult func addReceivedDataChannelMessageObserver<T: AnyObject>(_ observer: T,
                                                                                 closure: @escaping (T, Data) -> Void) -> ObservationToken {

        let observerId = UUID()

        observations.receivedDataChannelMessage[observerId] = { [weak self, weak observer] messageData in

            guard let observer = observer else {
                self?.observations.receivedDataChannelMessage.removeValue(forKey: observerId)
                return
            }

            closure(observer, messageData)

        }

        return ObservationToken { [weak self] in
            self?.observations.receivedDataChannelMessage.removeValue(forKey: observerId)
        }

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
        self.observations.discoveredLocalCandidate.values.forEach { closure in
            closure(self.workerId, candidate)
        }
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
        self.observations.receivedDataChannelMessage.values.forEach { closure in
            closure(buffer.data)
        }
    }

}
