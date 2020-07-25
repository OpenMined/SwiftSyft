import Foundation
import Combine
import SyftProto
import Network

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

/// Error struct that contains errors from the training cycle
public struct SyftClientError: Error {
    let message: String

    public var localizedDescription: String {
        return message
    }
}

struct SyftConnectionMetrics {
    let ping: Int
    let uploadSpeed: Double
    let downloadSpeed: Double
}

/// Syft client for static federated learning
public class SyftClient: SyftClientProtocol {
    private let url: URL
    private let signallingClient: SignallingClient?
    private let connectionType: SyftConnectionType
    private var authToken: String?

    init?(url: URL, connectionType: SyftConnectionType, authToken: String? = nil, signallingClient: SignallingClient? = nil) {
        self.signallingClient = signallingClient
        self.url = url
        self.authToken = authToken
        self.connectionType = connectionType
    }

    /// Initializes as `SyftClient` with a PyGrid server URL and an authentication token (if needed)
    /// - Parameters:
    ///   - url: Full URL to a PyGrid server (`ws`(websocket) and `http` protocols suppported)
    ///   - authToken: PyGrid authentication token
    convenience public init?(url: URL, authToken: String? = nil) {

        if url.scheme == "http" || url.scheme == "https"{

            self.init(url: url, connectionType: .http(url), authToken: authToken)

        } else if url.scheme == "ws" {

            let signallingClient = SignallingClient(url: url, pingInterval: 30)
            signallingClient.connect()
            let connectionType: SyftConnectionType = .socket(url: url,
                                                             sendMessageSubject: signallingClient.sendMessageSubject, receiveMessagePublisher: signallingClient.incomingMessagePublisher)
//            self.init(url: url, connectionType: connectionType, signallingClient: signallingClient)
            self.init(url: url, connectionType: connectionType, authToken: authToken, signallingClient: signallingClient)

        } else {
            return nil
        }

    }

    /// Creates a new federated learning cycle job with the given options
    /// - Parameters:
    ///   - modelName: Model name as it is stored in the PyGrid server you are connecting to
    ///   - version: Version of the model (ex. 1.0)
    /// - Returns: `SyftJob`
    public func newJob(modelName: String, version: String) -> SyftJob {

        return SyftJob(connectionType: self.connectionType,
                       modelName: modelName,
                       version: version,
                       authToken: self.authToken)
    }
}

/// Closure that accepts a diff from `SyftPlan.generateDiffData()`
/// - parameter diffData: diff data from `SyftPlan.generateDiffData()`.
public typealias ModelReport = (_ diffData: Data) -> Void

/// Represents a single training cycle done by the client
public class SyftJob: SyftJobProtocol {

    let url: URL
    var workerId: String?
    var requestKey: String?
    let modelName: String
    let version: String
    var authToken: String?
    private let connectionType: SyftConnectionType

    // Must be populated on `start`
    let download: String = "46"
    let ping: Int = 8
    let upload: String = "23"

    var onReadyBlock: (_ plan: SyftPlan, _ clientConfig: FederatedClientConfig, _ report: ModelReport) -> Void = { _, _, _ in }
    var onErrorBlock: (_ error: Error) -> Void = { _ in }
    var onRejectedBlock: (_ timeout: TimeInterval?) -> Void = { _ in }

    private var cyclePublisher: AnyPublisher<(SyftPlan, FederatedClientConfig), Error>?
    private var disposeBag = Set<AnyCancellable>()

    private let monitor = NWPathMonitor()

    init(connectionType: SyftConnectionType, modelName: String, version: String, authToken: String? = nil) {
        self.modelName = modelName
        self.version = version
        self.connectionType = connectionType
        self.authToken = authToken

        switch connectionType {
        case let .http(url):
            self.url = url
        case let .socket(url, sendMessageSubject: _, receiveMessagePublisher: _):
            self.url = url
        }

    }

    func isBatteryCharging() -> Bool {

        // Remember current batter monitoring setting to reset it after checking.
        let userBatteryMonitoringSetting = UIDevice.current.isBatteryMonitoringEnabled

        defer {
            UIDevice.current.isBatteryMonitoringEnabled = userBatteryMonitoringSetting
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        return UIDevice.current.batteryState == .charging

    }

    func validateWifiNetwork(isOnWifi: Bool) -> Future<Bool, Never> {

        if !isOnWifi {
            return Future { $0(.success(true)) }
        } else {

            return Future { promise in
                self.monitor.pathUpdateHandler = { path in
                    if path.usesInterfaceType(.wifi) {
                        promise(.success(true))
                    } else {
                        promise(.success(false))
                    }
                }
                self.monitor.start(queue: .global())
            }

        }

    }

    /// Starts the job executing the following actions:
    /// 1. Meters connection speed to PyGrid
    /// 2. Registers into training cycle on PyGrid
    /// 3. Retrieves cycle and client parameters.
    /// 4. Downloads Plans, Model and Protocols.
    /// 5. Triggers `onReady` handler
    /// - Parameters:
    ///   - chargeDetection: Specifies whether to check if device is charging before continuing job execution. Default is `true`.
    ///   - wifiDetection: Specifies whether to have wifi connection before continuing job execution. Default is `true`.
    public func start(chargeDetection: Bool = true, wifiDetection: Bool = true) {

        // Continue if battery charging check is false or if true, check that the device is indeed charging
        if chargeDetection && !self.isBatteryCharging() {
            let error = SyftClientError(message: "User requested that device should be charging when executing.")
            self.onErrorBlock(error)
            return
        }

        self.validateWifiNetwork(isOnWifi: wifiDetection).sink(receiveCompletion: { _ in }) { [weak self] networkIntefaceValid in

            guard let self = self else {
                return
            }

            if networkIntefaceValid {

                switch self.connectionType {
                case .http(let url):
                    self.startThroughHTTP(url: url, authToken: self.authToken)
                case let .socket(url, sendMessageSubject, receiveMessagePublisher):
                    self.startThroughSocket(url: url,
                                            sendMessageSubject: sendMessageSubject,
                                            receiveMessagePublisher: receiveMessagePublisher, authToken: self.authToken)
                }

            } else {

                self.onErrorBlock(SyftClientError(message: "Device not on wifi"))

            }
        }.store(in: &self.disposeBag)

    }

    func startThroughHTTP(url: URL, authToken: String?) {

        // Set-up authentication request
        let authURL = self.url.appendingPathComponent("model_centric/authenticate")
        var authRequest = URLRequest(url: authURL)
        authRequest.httpMethod = "POST"
        authRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        authRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        let authRequestBody = AuthRequest(authToken: authToken, model: self.modelName, version: self.version)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            let authBodyData = try encoder.encode(authRequestBody)
            authRequest.httpBody = authBodyData
        } catch {
            debugPrint("Error encoding auth request body")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let authPublisher = URLSession.shared.dataTaskPublisher(for: authRequest)
                                .map { $0.data }
                                .decode(type: AuthResponse.self, decoder: decoder)
                                .handleEvents(receiveOutput: { [unowned self] authResponse in
                                    self.workerId = authResponse.workerId
                                })
                                .eraseToAnyPublisher()

        // Auth response -> Get Ping/Downoad/Upload Speed -> Cycle Request
        let cycleResponsePublisher = authPublisher
                                        .flatMap { [unowned self] authResponse -> AnyPublisher<(workerId: String, connectionMetrics: SyftConnectionMetrics?), Error> in

                                            if authResponse.requiresSpeedTest {

                                                return self.getConnectionMetrics(workerId: authResponse.workerId)

                                            } else {

                                                return Just((workerId: authResponse.workerId, connectionMetrics: nil))
                                                    .mapError({ _ in
                                                        SyftClientError(message: "Impossible Error")
                                                    })
                                                    .eraseToAnyPublisher()

                                            }

                                        }
                                        .flatMap { [unowned self] (result) -> AnyPublisher<(cycleResponse: CycleResponseSuccess, workerId: String), Error> in
                                            let (workerId, connectionMetrics) = result
                                            return self.cycleRequest(forWorkerId: workerId, connectionMetrics: connectionMetrics)
                                        }
                                        .handleEvents(receiveOutput: { [unowned self] cycleResponse in
                                            let (cycleResponseSuccess, _) = cycleResponse
                                            self.requestKey = cycleResponseSuccess.requestKey
                                        })
                                        .share()
                                        .eraseToAnyPublisher()

        self.startPlanAndModelDownload(withCycleResponse: cycleResponsePublisher)

    }

    func getConnectionMetrics(workerId: String) -> AnyPublisher<(workerId: String, connectionMetrics: SyftConnectionMetrics?), Error> {

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

        clientConfigPublisher.zip(planPublisher, modelParamPublisher)
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    switch error {
                    case let error as CycleResponseFailed where error.status == "rejected":

                        guard let timeout = error.timeout else {
                            self.onRejectedBlock(nil)
                            return
                        }

                        self.onRejectedBlock(TimeInterval(timeout))
                    default:
                        self.onErrorBlock(error)
                    }
                }
            }, receiveValue: { [weak self] (clientConfig, trainingModule, modelParam) in
                let syftPlan = SyftPlan(trainingModule: trainingModule, modelState: modelParam)
                self?.onReadyBlock(syftPlan, clientConfig, {[weak self] data in self?.reportDiff(diffData: data)})
            }).store(in: &disposeBag)

    }

    func cycleRequest(forWorkerId workerId: String, connectionMetrics: SyftConnectionMetrics?) -> AnyPublisher<(cycleResponse: CycleResponseSuccess, workerId: String), Error> {

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let cycleRequestURL = self.url.appendingPathComponent("model_centric/cycle-request")
        var cycleRequest: URLRequest = URLRequest(url: cycleRequestURL)
        cycleRequest.httpMethod = "POST"
        cycleRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        cycleRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        //Create request body
        let cycleRequestBody = CycleRequest(workerId: workerId,
                                            model: self.modelName,
                                            version: self.version,
                                            ping: self.ping,
                                            download: connectionMetrics?.downloadSpeed,
                                            upload: connectionMetrics?.uploadSpeed)

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
        urlComponents.path = "/model_centric/get-model"
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
        urlComponents.path = "/model_centric/get-plan"
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

        // Authentication -> Connection Metrics -> Cycle Request
        receiveMessagePublisher.filter { socketMessageResponse -> Bool in
            switch socketMessageResponse {
            case .authRequestResponse:
                return true
            default:
                return false
            }
        }.tryMap { authRequestResponse -> AuthResponse in
            switch authRequestResponse {
            case .authRequestResponse(let result):
                switch result {
                case .success(let authResponse):
                    self.workerId = authResponse.workerId
                    return authResponse
                case .failure(let error):
                    throw error
                }
            default:
                throw SyftClientError(message: "Authentication Error Unknown Response")
            }
        }.flatMap { [unowned self] authResponse -> AnyPublisher<(workerId: String,
                                     connectionMetrics: SyftConnectionMetrics?), Error> in

            if authResponse.requiresSpeedTest {

                return self.getConnectionMetrics(workerId: authResponse.workerId)

            } else {

                return Just((workerId: authResponse.workerId, connectionMetrics: nil))
                    .mapError({ _ in
                        SyftClientError(message: "Impossible Error")
                    })
                    .eraseToAnyPublisher()

            }

        }.sink(receiveCompletion: { [unowned self] completionResult in

            switch completionResult {
            case .finished:
                break
            case .failure(let error):
                self.onErrorBlock(error)
            }

        }, receiveValue: { (result) in
            let (workerId, connectionMetrics) = result

            let cycleRequest = CycleRequest(workerId: workerId, model: self.modelName, version: self.version, ping: connectionMetrics?.ping, download: connectionMetrics?.downloadSpeed, upload: connectionMetrics?.uploadSpeed)
            sendMessageSubject.send(.cycleRequest(cycleRequest))

        }).store(in: &self.disposeBag)

        // Cycle Request Response -> Start Plan and model
        receiveMessagePublisher.sink(receiveCompletion: { [unowned self] completionResult in

            switch completionResult {
            case .finished:
                break
            case .failure(let error):
                self.onErrorBlock(error)
            }

        }, receiveValue: { [unowned self] cycleRequestResponse in
            switch cycleRequestResponse {
            case .cycleRequestResponse(let result):
                switch result {
                case .success(let cycleSuccess):
                    self.requestKey = cycleSuccess.requestKey
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

        sendMessageSubject.send(.authRequest(authToken: authToken, modelName: self.modelName, modelVersion: self.version))

    }

    func reportDiff(diffData: Data) {

        guard let workerId = self.workerId, let requestKey = self.requestKey else {
            return
        }

        let modelReportBody = FederatedReport(workerId: workerId, requestKey: requestKey, diff: diffData)

        switch self.connectionType {
        case .http:

            let jsonEncoder = JSONEncoder()

            let cycleRequestURL = self.url.appendingPathComponent("model_centric/report")
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

    /// Registers a closure to execute when the job is accepted into a training cycle.
    /// - Parameter execute: Closure that accepts the training plan (`SyftPlan`), training configuration (`FederatedClientConfig`) and reporting closure (`ModelReport`).
    /// All of these objects will be used during training.
    /// - parameter plan: `SyftPlan` use this to train your model and generate diffs
    /// - parameter clientConfig: contains training configuration such as batch size and learning rate.
    /// - parameter report: closure that accepts diffs as `Data` and sends them to PyGrid.
    public func onReady(execute: @escaping (_ plan: SyftPlan, _ clientConfig: FederatedClientConfig, _ report: ModelReport) -> Void) {
        self.onReadyBlock = execute
    }

    /// Registers a closure to execute whenever an error occurs during training cycle
    /// - Parameter execute: closure to execute during training cycle
    /// - parameter error: contains information about error that occurred
    public func onError(execute: @escaping (_ error: Error) -> Void) {
        self.onErrorBlock = execute
    }

    /// Registers a closure to execute whenever an error occurs during training cycle
    /// - Parameter execute: closure to execute during training cycle
    /// - parameter timeout: how long you need to wait before trying again
    public func onRejected(execute: @escaping (_ timeout: TimeInterval?) -> Void) {
        self.onRejectedBlock = execute
    }

}
