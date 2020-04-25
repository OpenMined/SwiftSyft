import Foundation
import Combine

class SyftRTCClient {

    let workerId: UUID
    let scopeId: UUID
    let webRTCClient: WebRTCClient
    let signallingClient: SignallingClient
    var disposeBag = Set<AnyCancellable>()

    init(socketURL: URL, workerId: UUID, scopeId: UUID, webRTCClient: WebRTCClient, signallingClient: SignallingClient) {

        self.workerId = workerId
        self.scopeId = scopeId
        self.signallingClient = signallingClient
        self.webRTCClient = webRTCClient

    }

    public convenience init (socketURL: URL, workerId: UUID, scopeId: UUID) {

        let signallingClient = SignallingClient(url: socketURL, pingInterval: 30)

        let webRTClient = WebRTCClient(workerId: workerId, scopeId: scopeId, webRTCPeerFactory: WebRTCPeer.init, sendSignallingMessage: signallingClient.send)

        self.init(socketURL: socketURL, workerId: workerId, scopeId: scopeId, webRTCClient: webRTClient, signallingClient: signallingClient)

        let subscription = self.signallingClient.incomingMessagePublisher.sink { [weak self] signallingMessage in
            switch signallingMessage {
            case .getProtocolResponse:
                self?.webRTCClient.start(workerId: workerId, scopeId: scopeId)
            default:
                self?.webRTCClient.received(signallingMessage)
            }
        }
        self.disposeBag.insert(subscription)

    }

    public func connect() {
        self.signallingClient.connect()
        self.signallingClient.send(.getProtocolRequest(workerId: self.workerId, scopeId: self.scopeId, protocolId: "50801316202"))
    }

}
