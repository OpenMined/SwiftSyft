import Foundation

struct CycleRequest: Codable {
    let workerId: UUID
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

struct FederatedClientConfig: Codable {}

public struct CycleResponseSuccess: Codable {
    let status: String
    let requestKey: String
    let trainingPlan: UUID
    let clientConfig: FederatedClientConfig
    let protocolId: UUID
    let model: UUID

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case requestKey = "request_key"
        case trainingPlan = "training_plan"
        case clientConfig = "client_config"
        case protocolId = "protocol"
        case model = "model"
    }
}

struct CycleResponseFailed: Codable {
    let status: String
    let timeout: Int

    enum CodingKeys: String, CodingKey {
        case status
        case timeout
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
