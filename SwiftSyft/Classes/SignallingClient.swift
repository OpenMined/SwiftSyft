import Foundation

class SignallingClient {

    private var socketClient: SocketClientProtocol
    weak var delegate: SignallingClientDelegate?

    init(url: URL,
         pingInterval: Double, socketClientFactory: (_ url: URL, _ pingInterval: Double) -> SocketClientProtocol  = SignallingClient.defaultSocketClientFactory) {
        self.socketClient = socketClientFactory(url, pingInterval)
        self.socketClient.delegate = self
    }

}

extension SignallingClient: SignallingClientProtocol {

    func connect() {
        self.socketClient.connect()
    }

    func disconnect() {
        self.socketClient.disconnect()
    }

    func send(_ message: SignallingMessages) throws {

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        self.socketClient.send(data: data)

    }

}

extension SignallingClient: SocketClientDelegate {

    func didConnect(_ socketClient: SocketClientProtocol) {
        // TODO: Start timer
    }

    func didDisconnect(_ socketClient: SocketClientProtocol) {
        // TODO: Stop timer
    }

    func didReceive(socketMessage result: Result<Data, Error>) {
        switch result {
        case .success(let messageData):
            let decoder = JSONDecoder()
            do {
                let message = try decoder.decode(SignallingMessages.self, from: messageData)
                self.delegate?.didReceive(message)
            } catch let error {
                debugPrint(error.localizedDescription)
            }
        case .failure(let error):
            debugPrint(error.localizedDescription)
        }
    }
}

extension SignallingClient {
    private class func defaultSocketClientFactory(url: URL, pingInterval: Double) -> SocketClientProtocol {

        guard url.absoluteString.hasPrefix("wss") else {
            preconditionFailure("Path for socket server shoud start with wss://")
        }

        let socketClient: SocketClientProtocol
        if #available(iOS 13.0, *) {
            socketClient = SyftWebSocketIOS13(url: url, pingInterval: pingInterval)
        } else {
            socketClient = SyftWebSocketIOS12(url: url, pingInterval: pingInterval)
        }
        return socketClient

    }
}
