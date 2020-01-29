import Foundation
import WebRTC

enum SignallingMessageRequest {
    case joinRoom(workerId: String, scopeId: String)
    case sendOffer(workerId: String, scopeId: String, receiverId: String, remoteDescription: RTCSessionDescription)
    case sendAnswer(workerId: String, scopeId: String, receiverId: String, remoteDescription: RTCSessionDescription)
    case sendIceCandidate(workerId: String, scopeId: String, receiverId: String, iceCandidate: RTCIceCandidate)

}

enum SignallingMessageResponse {

    case newPeerReceived(workerId: String)
    case offerReceived(senderId: String, remoteDescription: RTCSessionDescription)
    case answerReceived(senderId: String, remoteDescription: RTCSessionDescription)
    case iceCandidateReceived(senderId: String, iceCandidate: RTCIceCandidate)

}

extension RTCMediaConstraints {

    static func makeDefaultMediaConstraints() -> RTCMediaConstraints {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        return constraints
    }

}

extension RTCPeerConnection {

    static func makeDefaultRTCConnection(withIceServers iceServers: [String], shouldCreateDataChannel: Bool) -> (RTCPeerConnection, RTCDataChannel?) {

        let peerConfig = RTCConfiguration()
        peerConfig.iceServers = [RTCIceServer(urlStrings: iceServers)]
        peerConfig.sdpSemantics = .unifiedPlan
        peerConfig.continualGatheringPolicy = .gatherContinually

        let peerConnectionFactory = RTCPeerConnectionFactory()
        let peerConnection = peerConnectionFactory.peerConnection(with: peerConfig,
                                                                  constraints: RTCMediaConstraints.makeDefaultMediaConstraints(),
                                                                  delegate: nil)

        var dataChannel: RTCDataChannel?
        if shouldCreateDataChannel {
            dataChannel = peerConnection.dataChannel(forLabel: "dataChannel",
            configuration: RTCDataChannelConfiguration())
        }

        return (peerConnection, dataChannel)

    }
}

class WebRTCClient {

    var webRTCPeers: [UUID: WebRTCPeer] = [UUID: WebRTCPeer]()
    var workerId: String?
    var scopeId: String?
    let sendSignallingMessage: (SignallingMessageRequest) -> Void

    let iceServers: [String]

    init(workerId: String? = nil,
         scopeId: String? = nil,
         iceServers: [String] = ["stun:stun.l.google.com:19302",
         "stun:stun1.l.google.com:19302",
         "stun:stun2.l.google.com:19302",
         "stun:stun3.l.google.com:19302",
         "stun:stun4.l.google.com:19302"],
         sendSignallingMessage: @escaping (SignallingMessageRequest) -> Void) {

        self.workerId = workerId
        self.scopeId = scopeId
        self.iceServers = iceServers
        self.sendSignallingMessage = sendSignallingMessage

    }

    func start(workerId: String? = nil, scopeId: String? = nil) {
        self.workerId = workerId
        self.scopeId = scopeId

        if let workerId = workerId,
            let scopeId = scopeId {

            self.sendSignallingMessage(.joinRoom(workerId: workerId, scopeId: scopeId))

        }

    }

    func stopAllConnections() {
        for peer in self.webRTCPeers.values {
            peer.rtcDataChannel?.close()
        }

        self.webRTCPeers.removeAll()
    }

    func received(_ signallingMessage: SignallingMessageResponse) {

        switch signallingMessage {

        case .newPeerReceived(let workerIdToInvite):

            if let uuid = UUID(uuidString: workerIdToInvite),
               let currentWorkerId = self.workerId,
               let scopeId = self.scopeId {

                let (peerConnection, dataChannel) = RTCPeerConnection.makeDefaultRTCConnection(withIceServers: iceServers,
                                                                                               shouldCreateDataChannel: true)

                if let dataChannel = dataChannel {

                    let webRTCPeer = WebRTCPeer(workerId: workerIdToInvite,
                                                rtcPeerConnection: peerConnection,
                                                connectionType: .initiator(dataChannel))
                    self.webRTCPeers[uuid] = webRTCPeer

                    webRTCPeer.createOffer(observer: self,
                                           mediaConstraints: RTCMediaConstraints.makeDefaultMediaConstraints()) { observer, sessionDescription in

                            observer.sendSignallingMessage(.sendOffer(workerId: currentWorkerId,
                                                                  scopeId: scopeId,
                                                                  receiverId: workerIdToInvite,
                                                                  remoteDescription: sessionDescription))
                    }

                }
            }

        case .offerReceived(let offerSenderId, let remoteSessionDescription):
            if let uuid = UUID(uuidString: offerSenderId),
               let currentWorkerId = self.workerId,
               let scopeId = self.scopeId {

                    let (peerConnection, _) = RTCPeerConnection.makeDefaultRTCConnection(withIceServers: iceServers,
                                                                                     shouldCreateDataChannel: false)
                    let webRTCPeer = WebRTCPeer(workerId: offerSenderId,
                                            rtcPeerConnection: peerConnection,
                                            connectionType: .receiver)
                    self.webRTCPeers[uuid] = webRTCPeer

                    webRTCPeer.receivedOffer(observer: self,
                                             with: remoteSessionDescription) { observer, sessionDescription in

                        observer.sendSignallingMessage(.sendAnswer(workerId: currentWorkerId,
                                                               scopeId: scopeId,
                                                               receiverId: offerSenderId,
                                                               remoteDescription: sessionDescription))
                }
            }
        case .answerReceived(let senderId, let sessionDescription):
            if let uuid = UUID(uuidString: senderId) {

                self.webRTCPeers[uuid]?.receivedAnswer(with: sessionDescription)
            }
        case .iceCandidateReceived(let senderId, let iceCandidate):
            if let uuid = UUID(uuidString: senderId) {

                self.webRTCPeers[uuid]?.add(iceCandidate)

            }
        }

    }

    private func observe(_ webRTCPeer: WebRTCPeer) {

        webRTCPeer.addReceivedDataChannelMessageObserver(self) { (_, messageData) in
            if let messageString = String(bytes: messageData, encoding: .utf8) {
                debugPrint("Received message: \(messageString)")
            } else {
                debugPrint("Received message data")
            }
        }

        webRTCPeer.addDiscoveredLocalIceCandidateObserver(self) { (observer, receiverId, iceCandidate) in

            if let currentWorkerId = observer.workerId,
                let scopeId = observer.scopeId {

                observer.sendSignallingMessage(.sendIceCandidate(workerId: currentWorkerId,
                                                                 scopeId: scopeId,
                                                                 receiverId: receiverId,
                                                                 iceCandidate: iceCandidate))

            }

        }

    }

}
