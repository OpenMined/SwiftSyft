import Foundation
import WebRTC

extension RTCMediaConstraints {

    static func makeDefaultMediaConstraints() -> RTCMediaConstraints {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
                                                                    "RtpDataChannels": kRTCMediaConstraintsValueTrue ])
        return constraints
    }

}

extension RTCPeerConnection {

    static func makeDefaultRTCConnection(withIceServers iceServers: [String],
                                         shouldCreateDataChannel: Bool) -> (RTCPeerConnection, RTCDataChannel?) {

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

    private var webRTCPeers: [UUID: WebRTCPeer] = [UUID: WebRTCPeer]()
    private var workerId: UUID?
    private var scopeId: UUID?
    private let sendSignallingMessage: (SignallingMessages) -> Void
    private let webrtcPeerFactory: (_ workerId: UUID, _ rtcPeerConnection: RTCPeerConnection, _ connectionType: WebRTCConnectionType) -> WebRTCPeer
    private let iceServers: [String]

    init(workerId: UUID? = nil,
         scopeId: UUID? = nil,
         iceServers: [String] = ["stun:stun.l.google.com:19302",
         "stun:stun1.l.google.com:19302",
         "stun:stun2.l.google.com:19302",
         "stun:stun3.l.google.com:19302",
         "stun:stun4.l.google.com:19302"],
         webRTCPeerFactory: @escaping (_ workerId: UUID, _ rtcPeerConnection: RTCPeerConnection, _ connectionType: WebRTCConnectionType) -> WebRTCPeer = WebRTCPeer.init,
         sendSignallingMessage: @escaping (SignallingMessages) -> Void) {

        self.workerId = workerId
        self.scopeId = scopeId
        self.iceServers = iceServers
        self.webrtcPeerFactory = webRTCPeerFactory
        self.sendSignallingMessage = sendSignallingMessage

    }

    func start(workerId: UUID? = nil, scopeId: UUID? = nil) {

        if let workerId = workerId,
            let scopeId = scopeId {

            self.workerId = workerId
            self.scopeId = scopeId

        }

        self.sendSignallingMessage(.joinRoom(workerId: self.workerId!, scopeId: self.scopeId!))

    }

    func stopAllConnections() {
        for peer in self.webRTCPeers.values {
            peer.rtcDataChannel?.close()
        }

        self.webRTCPeers.removeAll()
    }

    func removePeer(workerUUID: UUID) {
        self.webRTCPeers[workerUUID]?.rtcDataChannel?.close()
        self.webRTCPeers[workerUUID] = nil
    }

    func received(_ signallingMessage: SignallingMessages) {

        switch signallingMessage {

        case .joinRoom(let workerUUIDToInvite, _):

            if  let currentWorkerId = self.workerId,
               let scopeId = self.scopeId {

                let (peerConnection, dataChannel) = RTCPeerConnection.makeDefaultRTCConnection(withIceServers: iceServers, shouldCreateDataChannel: true)

                if let dataChannel = dataChannel {

                    let webRTCPeer = self.webrtcPeerFactory(workerUUIDToInvite, peerConnection, .initiator(dataChannel))
                    self.webRTCPeers[workerUUIDToInvite] = webRTCPeer
                    observe(webRTCPeer)

                    webRTCPeer.createOffer(observer: self,
                                           mediaConstraints: RTCMediaConstraints.makeDefaultMediaConstraints()) { observer, sessionDescription in

                            observer.sendSignallingMessage(.webRTCInternalMessage(.sdpOffer(workerId: currentWorkerId, scopeId: scopeId, toId: workerUUIDToInvite, sdp: sessionDescription)))
                    }

                }
            }

        case .webRTCPeerLeft(let peerWorkerUUID, _):

            self.removePeer(workerUUID: peerWorkerUUID)

        case .webRTCInternalMessage(let webrtcInternalMessage):

            switch webrtcInternalMessage {

            case .sdpOffer(let offerSenderUUID, _, _, sdp: let remoteSessionDescription):

                if let currentWorkerId = self.workerId,
                   let scopeId = self.scopeId {

                        let (peerConnection, _) = RTCPeerConnection.makeDefaultRTCConnection(withIceServers: iceServers, shouldCreateDataChannel: false)
                        let webRTCPeer = self.webrtcPeerFactory(offerSenderUUID, peerConnection, .receiver)
                        self.webRTCPeers[offerSenderUUID] = webRTCPeer
                        observe(webRTCPeer)

                        webRTCPeer.receivedOffer(observer: self,
                                                 with: remoteSessionDescription) { observer, sessionDescription in

                            observer.sendSignallingMessage(.webRTCInternalMessage(.sdpAnswer(workerId: currentWorkerId, scopeId: scopeId, toId: offerSenderUUID, sdp: sessionDescription)))
                        }
                    }
            case .sdpAnswer(let answerSenderUUID, _, _, let sessionDescription):
                self.webRTCPeers[answerSenderUUID]?.receivedAnswer(with: sessionDescription)
            case .iceCandidate(let candidateSenderUUID, _, _, let iceCandidate):
                self.webRTCPeers[candidateSenderUUID]?.add(iceCandidate)
            }
        default:
            break
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

                observer.sendSignallingMessage(.webRTCInternalMessage(.iceCandidate(workerId: currentWorkerId,
                                                                                    scopeId: scopeId,
                                                                                    toId: receiverId,
                                                                                    sdp: iceCandidate)))

            }

        }

    }

}
