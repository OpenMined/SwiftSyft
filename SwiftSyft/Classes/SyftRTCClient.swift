import Foundation

public class SyftRTCClient {

    let workerId: UUID
    let scopeId: UUID
    let webRTCClient: WebRTCClient
    let signallingClient: SignallingClient

    init(socketURL: URL, workerId: UUID, scopeId: UUID, webRTCClient: WebRTCClient, signallingClient: SignallingClient) {

        self.workerId = workerId
        self.scopeId = scopeId
        self.signallingClient = signallingClient
        self.webRTCClient = webRTCClient
        self.signallingClient.delegate = self

    }

    public convenience init (socketURL: URL, workerId: UUID, scopeId: UUID) {

        let signallingClient = SignallingClient(url: socketURL, pingInterval: 30)

        let webRTClient = WebRTCClient(workerId: workerId, scopeId: scopeId, webRTCPeerFactory: WebRTCPeer.init, sendSignallingMessage: signallingClient.send)

        self.init(socketURL: socketURL, workerId: workerId, scopeId: scopeId, webRTCClient: webRTClient, signallingClient: signallingClient)

    }

    public func connect() {

        self.signallingClient.connect()
        self.signallingClient.send(.getProtocolRequest(workerId: self.workerId, scopeId: self.scopeId, protocolId: "50801316202"))
    }

}

extension SyftRTCClient: SignallingClientDelegate {

    func didReceive(_ message: SignallingMessages) {

        switch message {
        case .getProtocolResponse:
            self.webRTCClient.start(workerId: workerId, scopeId: scopeId)
        default:
             self.webRTCClient.received(message)
        }

    }

}
