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
    case initiator(RTCDataChannel)
    case receiver
}

/// Wraps a peer connection and its data channel. Allows other observers
/// to observer peer connection and data channel events.
class WebRTCPeer: NSObject {

    let workerId: UUID
    let rtcPeerConnection: RTCPeerConnection
    var rtcDataChannel: RTCDataChannel? {
        didSet {
            self.rtcDataChannel?.delegate = self
        }
    }
    var iceCandidates: [RTCIceCandidate] = []
    var connectionType: WebRTCConnectionType

    private var observations = (
        discoveredLocalCandidate: [UUID: (UUID, RTCIceCandidate) -> Void](),
        receivedDataChannelMessage: [UUID: (Data) -> Void]()
    )

    init(workerId: UUID, rtcPeerConnection: RTCPeerConnection, connectionType: WebRTCConnectionType) {
        self.workerId = workerId
        self.rtcPeerConnection = rtcPeerConnection
        self.connectionType = connectionType
        super.init()
        self.rtcPeerConnection.delegate = self

        switch connectionType {
        case .initiator(let dataChannel):
            self.rtcDataChannel = dataChannel
            self.rtcDataChannel?.delegate = self
        case .receiver:
            break
        }
    }

    func add(_ remoteIceCandidate: RTCIceCandidate) {
        self.rtcPeerConnection.add(remoteIceCandidate)
        iceCandidates.append(remoteIceCandidate)
    }

    func createOffer<T: AnyObject>(observer: T, mediaConstraints: RTCMediaConstraints, completion: @escaping (T, RTCSessionDescription) -> Void) {

        self.rtcPeerConnection.offer(for: mediaConstraints) { [weak self] sessionDescription, error in

            if let sessionDescription = sessionDescription {

                self?.rtcPeerConnection.setLocalDescription(sessionDescription, completionHandler: { [weak observer] error in

                    guard error != nil else {
                        debugPrint(error!.localizedDescription)
                        return
                    }

                    guard let observer = observer else {
                        return
                    }

                    completion(observer, sessionDescription)

                })

            }

        }

    }

    func receivedAnswer(with remoteSessionDescription: RTCSessionDescription) {
        self.rtcPeerConnection.setRemoteDescription(remoteSessionDescription) { error in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func receivedOffer<T: AnyObject>(observer: T,
                                     with remoteSessionDescription: RTCSessionDescription,
                                     completion: @escaping (T, RTCSessionDescription) -> Void) {

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                             optionalConstraints: nil)

        self.rtcPeerConnection.setRemoteDescription(remoteSessionDescription, completionHandler: { [weak self] error in
            guard error == nil else {
                return
            }

            self?.rtcPeerConnection.answer(for: constraints,
                                           completionHandler: { [weak self] localSessionDescription, error in
                guard let localSessionDescription = localSessionDescription else {
                    return
                }

                self?.rtcPeerConnection.setLocalDescription(localSessionDescription, completionHandler: { [weak observer] error in

                    guard error != nil else {
                        debugPrint(error!.localizedDescription)
                        return
                    }

                    guard let observer = observer else {
                        return
                    }

                    completion(observer, localSessionDescription)

                })
            })
        })

    }

    @discardableResult func addDiscoveredLocalIceCandidateObserver<T: AnyObject>(_ observer: T,
                                                                                    closure: @escaping (T, UUID, RTCIceCandidate) -> Void) -> ObservationToken {

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
