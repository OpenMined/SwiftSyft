import Foundation
import Combine
import SyftProto

enum SyftConnectionType {
    case http(URL)
    case socket(url: URL,
        sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>,
        receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>)

    var url: URL {
        switch self {
        case .http(let url):
            return url
        case .socket(url: let url, sendMessageSubject: _, receiveMessagePublisher: _):
            return url
        }
    }
}

struct SyftClientError: Error {
    let message: String
}

struct SyftConnectionMetrics {
    let ping: String
    let uploadSpeed: Double
    let downloadSpeed: Double
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

public typealias ModelReport = (Data) -> Void

public class SyftJob: SyftJobProtocol {

    let url: URL
    var workerId: String?
    var requestKey: String?
    let modelName: String
    let version: String
    private let connectionType: SyftConnectionType

    // Must be populated on `start`
    let download: String = "46"
    let ping: String = "8"
    let upload: String = "23"

    var onReadyBlock: (SyftPlan, FederatedClientConfig, ModelReport) -> Void = { _, _, _ in }
    var onErrorBlock: (Error) -> Void = { _ in }

    private var cyclePublisher: AnyPublisher<(SyftPlan, FederatedClientConfig), Error>?
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

        let authPublisher = URLSession.shared.dataTaskPublisher(for: authRequest)
                                .map { $0.data }
                                .decode(type: AuthResponse.self, decoder: decoder)
                                .map({ $0.workerId })
                                .eraseToAnyPublisher()

        // Save workerId
        authPublisher.sink(receiveCompletion: { _ in },
                           receiveValue: { [weak self] workerId in
                                                guard let self = self else {
                                                    return
                                                }

                                                self.workerId = workerId
                                         }).store(in: &disposeBag)

        // Auth response -> Get Ping/Downoad/Upload Speed -> Cycle Request
        let cycleResponsePublisher = authPublisher
                                        .flatMap { [unowned self] workerId -> AnyPublisher<(workerId: String, connectionMetrics: SyftConnectionMetrics), Error> in
                                            return self.getConnectionMetrics(workerId: workerId)
                                        }
                                        .flatMap { [unowned self] (result) -> AnyPublisher<(cycleResponse: CycleResponseSuccess, workerId: String), Error> in
                                            let (workerId, connectionMetrics) = result
                                            return self.cycleRequest(forWorkerId: workerId, connectionMetrics: connectionMetrics)
                                        }.eraseToAnyPublisher()

        self.startPlanAndModelDownload(withCycleResponse: cycleResponsePublisher)

    }

    func getConnectionMetrics(workerId: String) -> AnyPublisher<(workerId: String, connectionMetrics: SyftConnectionMetrics), Error> {

        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = self.url.host

        guard let connectionURL = urlComponents.url ,
              let _ = connectionURL.host,
              let port = self.url.port else {

            let urlError = URLError(.badURL)
            return Fail(error: urlError).eraseToAnyPublisher()

        }

        let networkManager = NetworkManager(url: connectionURL.absoluteString, port: port)

        let connectionMetricsPublisher = networkManager.uploadSpeedTest(workerId: workerId).zip(networkManager.downloadSpeedTest(workerId: workerId))

        return connectionMetricsPublisher.map { (result) -> (workerId: String, connectionMetrics: SyftConnectionMetrics) in
            let (uploadSpeed, downloadSpeed) = result
            return (workerId: workerId, connectionMetrics: SyftConnectionMetrics(ping: self.ping, uploadSpeed: uploadSpeed, downloadSpeed: downloadSpeed))
        }.eraseToAnyPublisher()

    }

    func startPlanAndModelDownload(withCycleResponse cycleResponsePublisher: AnyPublisher<(cycleResponse: CycleResponseSuccess, workerId: String), Error>) {

        // Filter out client config
        let clientConfigPublisher = cycleResponsePublisher
            .map { (cycleResponse) -> FederatedClientConfig in
                let (cycleResponseSuccess, _) = cycleResponse
                return cycleResponseSuccess.clientConfig
            }

        // Download model params
        let modelParamPublisher = cycleResponsePublisher
            .flatMap { (cycleResponse) -> AnyPublisher<Data, Error> in
                let (cycleResponseSuccess, workerId) = cycleResponse
                return self.downloadModel(forWorkerId: workerId, modelId: cycleResponseSuccess.modelId, requestKey: cycleResponseSuccess.requestKey)
            }
            .tryMap { try SyftProto_Execution_V1_State(serializedData: $0) }

        // Download plan
        let planPublisher = cycleResponsePublisher
            .flatMap { (cycleResponse) -> AnyPublisher<Data, Error> in
                let (cycleResponseSuccess, workerId) = cycleResponse
                return self.downloadPlan(forWorkerId: workerId, planId: cycleResponseSuccess.planConfig.planId, requestKey: cycleResponseSuccess.requestKey)
            }
//            .tryMap { try SyftProto_Types_Torch_V1_ScriptModule(serializedData: $0) }
            .tryMap { try SyftProto_Execution_V1_Plan(serializedData: $0) }
            .tryMap { torchScriptPlan -> String in

                // Save torchscript plan to filesystem before loading
                let torchscriptData = torchScriptPlan.torchscript

                let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                guard let documentDirectory = urls.first else {
                    throw SyftClientError(message: "Error saving plan. Saving not allowed")
                }

                let fileURL = documentDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pt")
                try torchscriptData.write(to: fileURL, options: .atomic)

                return fileURL.path
            }
            .map { TorchTrainingModule(fileAtPath: $0) }

        // Save request key
        cycleResponsePublisher.sink(receiveCompletion: { _ in }, receiveValue: { [weak self] (cycleResponse) in

            guard let self = self else {
                return
            }

            let (cycleResponseSuccess, _) = cycleResponse
            self.requestKey = cycleResponseSuccess.requestKey
        }).store(in: &disposeBag)

        clientConfigPublisher.zip(planPublisher, modelParamPublisher)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    print("finished")
                case .failure(let error):
                    self?.onErrorBlock(error)
                    print(error.localizedDescription)
                }
            }, receiveValue: { [weak self] (clientConfig, trainingModule, modelParam) in
                let syftPlan = SyftPlan(trainingModule: trainingModule, modelState: modelParam)
                self?.onReadyBlock(syftPlan, clientConfig, {[weak self] data in self?.reportDiff(diffData: data)})
            }).store(in: &disposeBag)

    }

    func cycleRequest(forWorkerId workerId: String, connectionMetrics: SyftConnectionMetrics) -> AnyPublisher<(cycleResponse: CycleResponseSuccess, workerId: String), Error> {

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let cycleRequestURL = self.url.appendingPathComponent("federated/cycle-request")
        var cycleRequest: URLRequest = URLRequest(url: cycleRequestURL)
        cycleRequest.httpMethod = "POST"
        cycleRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        cycleRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        //Create request body
        let cycleRequestBody = CycleRequest(workerId: workerId,
                                            model: self.modelName,
                                            version: self.version,
                                            ping: self.ping,
                                            download: String(connectionMetrics.downloadSpeed),
                                            upload: String(connectionMetrics.uploadSpeed))

        cycleRequest.httpBody = try? encoder.encode(cycleRequestBody)

        return URLSession.shared.dataTaskPublisher(for: cycleRequest)
                .map { $0.data }
                .decode(type: CycleResponse.self, decoder: decoder)
                .tryMap { cycleResponse -> (CycleResponseSuccess, String) in
                    switch cycleResponse {
                    case .success(let cycleResponseSuccess):
                        return (cycleResponse: cycleResponseSuccess, workerId: workerId)
                    case .failure(let cycleResponseFailure):
                        throw cycleResponseFailure
                    }
                }
                .eraseToAnyPublisher()
    }

    func downloadModel(forWorkerId workerId: String, modelId: Int, requestKey: String) -> AnyPublisher<Data, Error> {

        var urlComponents = URLComponents()
        urlComponents.scheme = self.url.scheme
        urlComponents.port = self.url.port
        urlComponents.host = self.url.host
        urlComponents.path = "/federated/get-model"
        urlComponents.queryItems = [
            URLQueryItem(name: "worker_id", value: workerId),
            URLQueryItem(name: "model_id", value: String(modelId)),
            URLQueryItem(name: "request_key", value: requestKey)
        ]

        guard let downloadModelURL = urlComponents.url else {
            let urlError = URLError(.badURL)
            return Fail(error: urlError).eraseToAnyPublisher()
        }

        var downloadModelRequest = URLRequest(url: downloadModelURL)
        downloadModelRequest.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: downloadModelRequest)
                    .map { $0.data }
                    .mapError { $0 as Error}
                    .eraseToAnyPublisher()

    }

    func downloadPlan(forWorkerId workerId: String, planId: Int, requestKey: String) -> AnyPublisher<Data, Error> {

        var urlComponents = URLComponents()
        urlComponents.scheme = self.url.scheme
        urlComponents.port = self.url.port
        urlComponents.host = self.url.host
        urlComponents.path = "/federated/get-plan"
        urlComponents.queryItems = [
            URLQueryItem(name: "worker_id", value: workerId),
            URLQueryItem(name: "plan_id", value: String(planId)),
            URLQueryItem(name: "request_key", value: requestKey),
            URLQueryItem(name: "receive_operations_as", value: "torchscript")
        ]

        guard let downloadModelURL = urlComponents.url else {
            let urlError = URLError(.badURL)
            return Fail(error: urlError).eraseToAnyPublisher()
        }

        var downloadPlanRequest = URLRequest(url: downloadModelURL)
        downloadPlanRequest.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: downloadPlanRequest)
                    .map { $0.data }
                    .mapError { $0 as Error}
                    .eraseToAnyPublisher()

    }

    func startThroughSocket(url: URL,
                                   sendMessageSubject: PassthroughSubject<SignallingMessagesRequest, Never>,
                                   receiveMessagePublisher: AnyPublisher<SignallingMessagesResponse, Never>, authToken: String?) {

        sendMessageSubject.send(.authRequest(authToken: authToken))

        // Authentication -> Connection Metrics -> Cycle Request
        receiveMessagePublisher.filter { socketMessageResponse -> Bool in
            switch socketMessageResponse {
            case .authRequestResponse:
                return true
            default:
                return false
            }
        }.tryMap { authRequestResponse -> String in
            switch authRequestResponse {
            case .authRequestResponse(let result):
                switch result {
                case .success(let workerId):
                    self.workerId = workerId
                    return workerId
                case .failure(let error):
                    throw error
                }
            default:
                throw SyftClientError(message: "Authentication Error Unknown Response")
            }
        }.flatMap { [unowned self] workerId -> AnyPublisher<(workerId: String,
                                     connectionMetrics: SyftConnectionMetrics), Error> in

            return self.getConnectionMetrics(workerId: workerId)

        }.sink(receiveCompletion: { _ in }, receiveValue: { (result) in
            let (workerId, connectionMetrics) = result

            let cycleRequest = CycleRequest(workerId: workerId, model: self.modelName, version: self.version, ping: String(connectionMetrics.ping), download: String(connectionMetrics.downloadSpeed), upload: String(connectionMetrics.uploadSpeed))
            sendMessageSubject.send(.cycleRequest(cycleRequest))

        }).store(in: &self.disposeBag)

        // Cycle Request Response -> Start Plan and model
        receiveMessagePublisher.sink(receiveCompletion: { _ in }, receiveValue: { cycleRequestResponse in
            switch cycleRequestResponse {
            case .cycleRequestResponse(let result):
                switch result {
                case .success(let cycleSuccess):
                    if let workerId = self.workerId {
                        let cycleResponsePublisher = CurrentValueSubject<(cycleResponse: CycleResponseSuccess,
                            workerId: String), Error>((cycleResponse: cycleSuccess, workerId: workerId)).eraseToAnyPublisher()
                        self.startPlanAndModelDownload(withCycleResponse: cycleResponsePublisher)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    return
                }
            default:
                break
            }
        }).store(in: &disposeBag)
    }

    public func reportDiff(diffData: Data) {

        guard let workerId = self.workerId, let requestKey = self.requestKey else {
            return
        }

        let modelReportBody = FederatedReport(workerId: workerId, requestKey: requestKey, diff: diffData)

        switch self.connectionType {
        case .http:

            let jsonEncoder = JSONEncoder()

            let cycleRequestURL = self.url.appendingPathComponent("federated/report")
            var reportRequest: URLRequest = URLRequest(url: cycleRequestURL)
            reportRequest.httpMethod = "POST"
            reportRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            reportRequest.addValue("application/json", forHTTPHeaderField: "Accept")

            reportRequest.httpBody = try? jsonEncoder.encode(modelReportBody)

            URLSession.shared.dataTask(with: reportRequest) { (responseData, _, _) in
                if let responseData = responseData {
                    debugPrint("Model report response: \(String(bytes: responseData, encoding: .utf8)!)")
                }
            }.resume()

        case .socket(url: _, let sendMessageSubject, _):

            sendMessageSubject.send(.modelReport(modelReportBody))

        }
    }

    public func onReady(execute: @escaping (SyftPlan, FederatedClientConfig, ModelReport) -> Void) {
        self.onReadyBlock = execute
    }

    public func onError(execute: @escaping (Error) -> Void) {
        self.onErrorBlock = execute
    }

}
