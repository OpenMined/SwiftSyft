import Foundation
import Combine

enum SyftConnectionType {
    case http(URL)
    case socket(URL)
}

public class SyftClient: SyftClientProtocol {
    private let url: URL
    private let signallingClient: SignallingClient
    private let connectionType: SyftConnectionType

    init?(url: URL, signallingClient: SignallingClient) {

        let connectionType: SyftConnectionType
        if url.scheme == "http://" {
            connectionType = .http(url)
        } else if url.scheme == "ws://" {
            connectionType = .socket(url)
        } else {
            return nil
        }

        self.signallingClient = signallingClient
        self.url = url
        self.connectionType = connectionType
    }

    convenience public init?(url: URL) {
        let signallingClient = SignallingClient(url: url, pingInterval: 30)
        self.init(url: url, signallingClient: signallingClient)
    }

    public func newJob(modelName: String, version: String) -> SyftJob {

        return SyftJob(url: self.url,
                       modelName: modelName,
                       version: version,
                       connectionType: self.connectionType,
                       sendMessageSubject: self.signallingClient.sendMessageSubject,
                       receiveMessagePublisher: self.signallingClient.incomingMessagePublisher)
    }
}

public class SyftJob: SyftJobProtocol {

    let url: URL
    var workerUUID: UUID?
    let modelName: String
    let version: String
    private let connectionType: SyftConnectionType

    // Must be populated on `start`
    let download: String = ""
    let ping: String = ""
    let upload: String = ""

    var onAcceptedBlock: (CycleResponseSuccess) -> Void = { _ in }

    private var disposeBag = Set<AnyCancellable>()

    // Used to observe incoming socket messages
    private let receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>

    /// Used to send message subject
    private let sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>

    init(url: URL, modelName: String,
         version: String,
         connectionType: SyftConnectionType,
         sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>,
         receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>) {
        self.url = url
        self.modelName = modelName
        self.version = version
        self.connectionType = connectionType
        self.sendMessageSubject = sendMessageSubject
        self.receiveMessagePublisher = receiveMessagePublisher
    }

    /// Request to join a federated learning cycle at "federated/cycle-request" endpoint (https://github.com/OpenMined/PyGrid/issues/445)
    public func start() {

        switch self.connectionType {
        case .http(let url):
            self.startThroughHTTP(url: url, authToken: nil)
        case .socket(let url):
            self.startThroughSocket(url: url, authToken: nil)
        }

    }

    func startThroughHTTP(url: URL, authToken: String?) {

        // TODO: Execute an authentication request to PyGrid:
        // URL endpoint: POST federated/authenticate
        // TODO: Retry this request if failed

        // TODO: Chain a successful authenticate request to an FL Worker Cycle Request
        // URL endpoint: POST federated/cycle-request
        // Params: JSON Body . Refer to `CycleRequest` struct in FederatedLearningMessages

        // TODO: If both requests are successful above
        // Create download request for the model, plan and protocol(if available)

        // TODO: Save a `Subscriber` in a property that is fired as long as the requests above are successful.

    }

    public func startThroughSocket(url: URL, authToken: String?) {

        self.sendMessageSubject.send(.authRequest(authToken: authToken))
        self.receiveMessagePublisher.sink { [weak self] socketMessageResponse in

            if let self = self {

                switch socketMessageResponse {
                case .authRequestResponse(let result):
                    switch result {
                    case .success(let workerUUID):

                        self.workerUUID = workerUUID
                        let cycleRequest = CycleRequest(workerId: workerUUID, model: self.modelName, version: self.version, ping: self.ping, download: self.download, upload: self.upload)
                        self.sendMessageSubject.send(.cycleRequest(cycleRequest))
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
