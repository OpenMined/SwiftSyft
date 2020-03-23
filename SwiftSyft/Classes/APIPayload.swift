import Foundation

struct AuthRequest: Codable {
    let authToken: String
}

struct AuthResponse: Codable {
    let workerId: String
}

struct CycleRequest: Codable {
    let workerId: String
    let model: String
    let version: String
    let ping: String
    let download: String
    let upload: String

    enum CodingKeys: String, CodingKey {
        case workerId = "worker_id"
        case model
        case version
        case ping
        case download
        case upload
    }
}

enum CycleResponse {
    case success(CycleResponseSuccess)
    case failure(CycleResponseFailed)
}

extension CycleResponse: Decodable {

    init(from decoder: Decoder) throws {

        do {
            self = .success(try CycleResponseSuccess(from: decoder))
        } catch {
            self = .failure(try CycleResponseFailed(from: decoder))
        }

    }

}

public struct CycleResponseSuccess: Decodable {
    let status: String
    let requestKey: String
    let model: String
    let modelId: Int
    let clientConfig: FederatedClientConfig

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case requestKey = "request_key"
        case modelId = "model_id"
        case model = "model"
        case clientConfig = "client_config"
    }
}

public extension CycleResponseSuccess {

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CycleResponseSuccess.CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        requestKey = try container.decode(String.self, forKey: .requestKey)
        model = try container.decode(String.self, forKey: .model)
        modelId = try container.decode(Int.self, forKey: .modelId)

        let nestedContainer = try container.nestedContainer(keyedBy: FederatedClientConfig.CodingKeys.self, forKey: .clientConfig)
        let name =  try nestedContainer.decode(String.self, forKey: .name)
        let version =  try nestedContainer.decode(String.self, forKey: .version)
        let batchSize =  try nestedContainer.decode(Int.self, forKey: .batchSize)
        let learningRate =  try nestedContainer.decode(Float.self, forKey: .learningRate)
        let maxUpdates =  try nestedContainer.decode(Int.self, forKey: .maxUpdates)
        clientConfig = FederatedClientConfig(name: name, version: version, batchSize: batchSize, learningRate: learningRate, maxUpdates: maxUpdates)
    }
}

struct CycleResponseFailed: Codable {
    let status: String
    var timeout: Int?
    var error: String?

    enum CodingKeys: String, CodingKey {
        case status
        case timeout
        case error
    }
}

extension CycleResponseFailed {

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        timeout = try container.decodeIfPresent(Int.self, forKey: .timeout)
        error = try container.decodeIfPresent(String.self, forKey: .error)

    }

}

struct FederatedClientConfig: Codable {
    let name: String
    let version: String
    let batchSize: Int
    let learningRate: Float
    let maxUpdates: Int

    enum CodingKeys: String, CodingKey {
        case name
        case version
        case batchSize = "batch_size"
        case learningRate = "lr"
        case maxUpdates = "max_updates"
    }
}

// From https://medium.com/@JinwooChoi/passing-parameters-to-restful-api-with-swift-codable-d78eb78f7b1
protocol DictionaryEncodable: Encodable {}
extension DictionaryEncodable {
    func dictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        guard let json = try? encoder.encode(self),
            let dict = try? JSONSerialization.jsonObject(with: json, options: []) as? [String: Any] else {
                return nil
        }
        return dict
    }
}

struct TrainingPlanDownloadParams: DictionaryEncodable {
    let workerId: String
    let requestKey: String
    let trainingPlan: String
}

struct ProtocolDownloadParams: DictionaryEncodable {
    let workerId: String
    let requestKey: String
    let protocolId: String
}

struct ModelDownloadParams: DictionaryEncodable {
    let workerId: String
    let requestKey: String
    let modelId: String
}

struct FederatedReport: Codable {
    let workerId: String
    let requestKey: String
    let diff: String
}
