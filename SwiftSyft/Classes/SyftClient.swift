import Foundation
import Combine

enum SyftConnectionType {
    case http(URL)
    case socket(url: URL,
        sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>,
        receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>)
}

public class SyftClient: SyftClientProtocol {
    private let url: URL
    private let signallingClient: SignallingClient?
    private let connectionType: SyftConnectionType

    init?(url: URL, connectionType: SyftConnectionType, signallingClient: SignallingClient? = nil) {
        self.signallingClient = signallingClient
        self.url = url
        self.connectionType = connectionType
    }

    convenience public init?(url: URL) {

        if url.scheme == "http" {

            self.init(url: url, connectionType: .http(url))

        } else if url.scheme == "ws" {

            let signallingClient = SignallingClient(url: url, pingInterval: 30)
            signallingClient.connect()
            let connectionType: SyftConnectionType = .socket(url: url,
                                                             sendMessageSubject: signallingClient.sendMessageSubject, receiveMessagePublisher: signallingClient.incomingMessagePublisher)
            self.init(url: url, connectionType: connectionType, signallingClient: signallingClient)

        } else {
            return nil
        }

    }

    public func newJob(modelName: String, version: String) -> SyftJob {

        return SyftJob(connectionType: self.connectionType,
                       modelName: modelName,
                       version: version)
    }
}

public class SyftJob: SyftJobProtocol {

    let url: URL
    var workerId: String?
    let modelName: String
    let version: String
    private let connectionType: SyftConnectionType

    // Must be populated on `start`
    let download: String = "46"
    let ping: String = "8"
    let upload: String = "23"

    var onAcceptedBlock: (CycleResponseSuccess) -> Void = { _ in }

    private var disposeBag = Set<AnyCancellable>()

    // Used to observe incoming socket messages
//    private let receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>

    /// Used to send message subject
//    private let sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>

    init(connectionType: SyftConnectionType, modelName: String, version: String) {
        self.modelName = modelName
        self.version = version
        self.connectionType = connectionType

        switch connectionType {
        case let .http(url):
            self.url = url
        case let .socket(url, sendMessageSubject: _, receiveMessagePublisher: _):
            self.url = url
        }

    }

    /// Request to join a federated learning cycle at "federated/cycle-request" endpoint (https://github.com/OpenMined/PyGrid/issues/445)
    public func start() {

        switch self.connectionType {
        case .http(let url):
            self.startThroughHTTP(url: url, authToken: nil)
        case let .socket(url, sendMessageSubject, receiveMessagePublisher):
            self.startThroughSocket(url: url,
                                    sendMessageSubject: sendMessageSubject,
                                    receiveMessagePublisher: receiveMessagePublisher, authToken: nil)
        }

    }

    func startThroughHTTP(url: URL, authToken: String?) {

        // Set-up authentication request
        let authURL = self.url.appendingPathComponent("federated/authenticate")
        var authRequest = URLRequest(url: authURL)
        authRequest.httpMethod = "POST"
        if let authToken = authToken {
            let authRequestBody = AuthRequest(authToken: authToken)
            let encoder = JSONEncoder()
            do {
                let authBodyData = try encoder.encode(authRequestBody)
                authRequest.httpBody = authBodyData
            } catch {
                debugPrint("Error encoding auth request body")
            }
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        URLSession.shared.dataTaskPublisher(for: authRequest)
            .map { $0.data }
            .decode(type: AuthResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
            .map({ $0.workerId })
            .flatMap { [unowned self] workerId in
                return self.cycleRequest(forWorkerId: workerId)
            }
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .failure(let error):
                    // TODO: Call on error block
                    debugPrint(error.localizedDescription)
                case .finished:
                    return
                }
            }, receiveValue: { cycleResponse in
            switch cycleResponse {
            case .success(_):
                // TODO: Start federated cycle
                debugPrint("Cycle request success")
            case .failure(_):
                // TODO: Call on error block
                debugPrint("Cycle response failure")
                }
            })
            .store(in: &disposeBag)

    }

    func cycleRequest(forWorkerId workerId: String) -> AnyPublisher<CycleResponse, Error> {

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let cycleRequestURL = self.url.appendingPathComponent("federated/cycle-request")
        var cycleRequest = URLRequest(url: cycleRequestURL)
        cycleRequest    .httpMethod = "POST"
        cycleRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        cycleRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        //Create request body
        let cycleRequestBody = CycleRequest(workerId: workerId, model: self.modelName, version: self.version, ping: self.ping, download: self.download, upload: self.upload)
        cycleRequest.httpBody = try? encoder.encode(cycleRequestBody)

        return URLSession.shared.dataTaskPublisher(for: cycleRequest)
                .map { $0.data }
                .decode(type: CycleResponse.self, decoder: decoder)
                .eraseToAnyPublisher()
    }

    func startThroughSocket(url: URL,
                                   sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>,
                                   receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>, authToken: String?) {

        sendMessageSubject.send(.authRequest(authToken: authToken))
        receiveMessagePublisher.sink { [weak self] socketMessageResponse in

            if let self = self {

                switch socketMessageResponse {
                case .authRequestResponse(let result):
                    switch result {
                    case .success(let workerId):

                        self.workerId = workerId
                        let cycleRequest = CycleRequest(workerId: workerId, model: self.modelName, version: self.version, ping: self.ping, download: self.download, upload: self.upload)
                        print(cycleRequest.workerId)
                        sendMessageSubject.send(.cycleRequest(cycleRequest))
                    case .failure(let error):
                        print(error.localizedDescription)
                        return
                    }
                case .cycleRequestResponse(let result):
                    switch result {
                    case .success(let cycleSuccess):
                        self.onAcceptedBlock(cycleSuccess)
                    case .failure(let error):
                        print(error.localizedDescription)
                        return
                    }
                default:
                    return
                }

            }

        }.store(in: &self.disposeBag)

    }

    public func onAccepted(execute: @escaping (CycleResponseSuccess) -> Void) {
        self.onAcceptedBlock = execute
    }

    /// Report the results of the learning cycle to PyGrid at "federated
    public func report() {
        // TODO: Send job report after onAccepted finishes execution
        //
    }

}
