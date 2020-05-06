import Foundation
import Combine

class SignallingClient {

    private var socketClient: SocketClientProtocol
    private let pingInterval: Double
    private let timerProvider: Timer.Type
    private var timer: Timer?

    var disposeBag = Set<AnyCancellable>()

    /// Used to let other components send socket messages
    let sendMessageSubject = PassthroughSubject<SignallingMessagesRequest, Never>()

    /// Used to subscribe to incoming messages
    private let incomingMessageSubject = PassthroughSubject<SignallingMessagesResponse, Never>()
    var incomingMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never> {
        return incomingMessageSubject.eraseToAnyPublisher()
    }

    init(url: URL,
         pingInterval: Double, timerProvider: Timer.Type = Timer.self, socketClientFactory: (_ url: URL, _ pingInterval: Double) -> SocketClientProtocol  = SignallingClient.defaultSocketClientFactory) {
        self.socketClient = socketClientFactory(url, pingInterval)
        self.pingInterval = pingInterval
        self.timerProvider = timerProvider
        self.socketClient.delegate = self

        let cancellable = self.sendMessageSubject.sink { [weak self] messageRequest in
            self?.send(messageRequest)
        }
        disposeBag.insert(cancellable)
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

    func send(_ message: SignallingMessagesRequest) {

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            self.socketClient.send(data: data)
        } catch let error {
            debugPrint(error.localizedDescription)
        }

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
        timer?.fire()
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
                let message = try decoder.decode(SignallingMessagesResponse.self, from: messageData)
                self.incomingMessageSubject.send(message)
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

        #if !DEBUG
        guard url.absoluteString.hasPrefix("wss") else {
            preconditionFailure("Path for socket server shoud start with wss://")
        }
        #endif

        let socketClient = SyftWebSocket(url: url, pingInterval: pingInterval)
        return socketClient

    }
}
