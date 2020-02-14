import Foundation

class SignallingClient {

    private var socketClient: SocketClientProtocol
    private let pingInterval: Double
    private let timerProvider: Timer.Type
    private var timer: Timer?
    weak var delegate: SignallingClientDelegate?

    init(url: URL,
         pingInterval: Double, timerProvider: Timer.Type = Timer.self, socketClientFactory: (_ url: URL, _ pingInterval: Double) -> SocketClientProtocol  = SignallingClient.defaultSocketClientFactory) {
        self.socketClient = socketClientFactory(url, pingInterval)
        self.pingInterval = pingInterval
        self.timerProvider = timerProvider
        self.socketClient.delegate = self
    }

    deinit {
        timer?.invalidate()
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
        guard timer == nil else { return }
        timer = self.timerProvider.scheduledTimer(withTimeInterval: self.pingInterval, repeats: true, block: { [weak self] _ in

            let keepAliveMessage = ["type": "socket-ping"]
            do {
                let data = try JSONSerialization.data(withJSONObject: keepAliveMessage, options: .sortedKeys)
                self?.socketClient.send(data: data)
            } catch {
                debugPrint("Error sending keep alive message")
            }
        })
    }

    func didDisconnect(_ socketClient: SocketClientProtocol) {
        self.timer?.invalidate()
        self.timer = nil
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

        let socketClient = SyftWebSocketIOS13(url: url, pingInterval: pingInterval)
        return socketClient

    }
}
