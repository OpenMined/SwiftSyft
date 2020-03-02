import WebRTC
import Foundation

enum SignallingMessagesRequest {
    // Federated Learning
    case authRequest(authToken: String?)
    case cycleRequest(CycleRequest)

    case getProtocolRequest(workerId: UUID, scopeId: UUID, protocolId: String)
    case getProtocolResponse
    case joinRoom(workerId: UUID, scopeId: UUID)
    case webRTCPeerLeft(workerId: UUID, scopeId: UUID)
    case webRTCInternalMessage(WebRTCInternalMessage)

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    enum DataPayloadCodingKeys: String, CodingKey {
        case workerId
        case scopeId
        case protocolId
        case authToken = "auth_token"
    }
}

enum SignallingMessagesResponse {

    case authRequestResponse(Result<UUID, Error>)

    case getProtocolRequest(workerId: UUID, scopeId: UUID, protocolId: String)
    case getProtocolResponse
    case joinRoom(workerId: UUID, scopeId: UUID)
    case webRTCPeerLeft(workerId: UUID, scopeId: UUID)
    case webRTCInternalMessage(WebRTCInternalMessage)

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    enum DataPayloadCodingKeys: String, CodingKey {
        case workerId
        case scopeId
        case protocolId
    }

    enum AuthenticationCodingKeys: String, CodingKey {
        case workerId = "worker_id"
        case error
    }
}

struct AuthenticationError: Error {
    let message: String
}

enum WebRTCInternalMessage {
    case sdpOffer(workerId: UUID, scopeId: UUID, toId: UUID, sdp: RTCSessionDescription)
    case sdpAnswer(workerId: UUID, scopeId: UUID, toId: UUID, sdp: RTCSessionDescription)
    case iceCandidate(workerId: UUID, scopeId: UUID, toId: UUID, sdp: RTCIceCandidate)

    enum CodingKeys: String, CodingKey {
        case workerId = "workerId"
        case scopeId = "scopeId"
        case toId = "to"
        case type = "type"
        case data = "data"
    }

    enum SessionDescriptionCodingKeys: String, CodingKey {
        case sdp
        case type
    }

    enum IceCandidateCodingKeys: String, CodingKey {
        case candidate
        case sdpMLineIndex
        case sdpMid
    }

}

/// This enum is a swift wrapper over `RTCSdpType` for easy encode and decode. From https://github.com/stasel/WebRTC-iOS
enum SdpType: String, Codable {
    case offer, prAnswer, answer

    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:    return .offer
        case .answer:   return .answer
        case .prAnswer: return .prAnswer
        }
    }
}

/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode. From https://github.com/stasel/WebRTC-iOS
struct SessionDescription: Codable {
    let sdp: String
    let type: SdpType

    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp

        switch rtcSessionDescription.type {
        case .offer:    self.type = .offer
        case .prAnswer: self.type = .prAnswer
        case .answer:   self.type = .answer
        @unknown default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescription.type.rawValue)")
        }
    }

    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}

/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode. From https://github.com/stasel/WebRTC-iOS
struct IceCandidate: Codable {
    let candidate: String
    let sdpMLineIndex: Int32
    let sdpMid: String?

    init(from iceCandidate: RTCIceCandidate) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.candidate = iceCandidate.sdp
    }

    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.candidate, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}

extension WebRTCInternalMessage: Decodable {

    // swiftlint:disable function_body_length
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "offer" {
            let workerId = try container.decode(String.self, forKey: .workerId)
            let scopeId = try container.decode(String.self, forKey: .scopeId)
            let toId = try container.decode(String.self, forKey: .toId)
            let data = try container.decode(SessionDescription.self, forKey: .data)
            if let workerUUID = UUID(uuidString: workerId),
                let scopeUUID = UUID(uuidString: scopeId),
                let toId =  UUID(uuidString: toId) {

                self = .sdpOffer(workerId: workerUUID,
                                 scopeId: scopeUUID,
                                 toId: toId,
                                 sdp: RTCSessionDescription(type: .offer, sdp: data.sdp))

            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else if type == "answer" {

            let workerId = try container.decode(String.self, forKey: .workerId)
            let scopeId = try container.decode(String.self, forKey: .scopeId)
            let toId = try container.decode(String.self, forKey: .toId)
            let data = try container.decode(SessionDescription.self, forKey: .data)
            if let workerUUID = UUID(uuidString: workerId),
               let scopeUUID = UUID(uuidString: scopeId),
               let toId =  UUID(uuidString: toId) {

                self = .sdpAnswer(workerId: workerUUID,
                                  scopeId: scopeUUID,
                                  toId: toId,
                                  sdp: RTCSessionDescription(type: .answer, sdp: data.sdp))

            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else if type == "candidate" {

            let workerId = try container.decode(String.self, forKey: .workerId)
            let scopeId = try container.decode(String.self, forKey: .scopeId)
            let toId = try container.decode(String.self, forKey: .toId)
            let data = try container.decode(IceCandidate.self, forKey: .data)
            if let workerUUID = UUID(uuidString: workerId),
               let scopeUUID = UUID(uuidString: scopeId),
               let toId =  UUID(uuidString: toId) {

                let iceCandidate = data.rtcIceCandidate
                self = .iceCandidate(workerId: workerUUID, scopeId: scopeUUID, toId: toId, sdp: iceCandidate)

            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else {
            throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                         debugDescription: "Invalid type value"))
        }
    }
    // swiftlint:enable function_body_length

}

extension SignallingMessagesRequest: Encodable {

    // swiftlint:disable function_body_length
    // swiftlint:disable:next cyclomatic_complexity
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .authRequest(let authToken):
            try container.encode("federated/authenticate", forKey: .type)
            if let authToken = authToken {
                var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
                try dataPayloadContainer.encode(authToken, forKey: .authToken)
            }
        case .cycleRequest(let cycleRequest):
            try container.encode("federated/cycle-request", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: CycleRequest.CodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(cycleRequest.workerId.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(cycleRequest.model, forKey: .model)
            try dataPayloadContainer.encode(cycleRequest.version, forKey: .version)
            try dataPayloadContainer.encode(cycleRequest.ping, forKey: .ping)
            try dataPayloadContainer.encode(cycleRequest.download, forKey: .download)
            try dataPayloadContainer.encode(cycleRequest.upload, forKey: .upload)
        case .getProtocolRequest(let workerUUID, let scopeUUID, let protocolId):
            try container.encode("get-protocol", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
            try dataPayloadContainer.encode(protocolId, forKey: .protocolId)
        case .joinRoom(let workerUUID, let scopeUUID):
            try container.encode("webrtc: join-room", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
        case .webRTCPeerLeft(let workerUUID, let scopeUUID):
            try container.encode("webrtc: peer-left", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
        case .webRTCInternalMessage(let webRTCInternalMessage):
            try container.encode("webrtc: internal-message", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: WebRTCInternalMessage.CodingKeys.self,
                                                                 forKey: .data)
            switch webRTCInternalMessage {
            case .sdpOffer(let workerUUID, let scopeUUID, let toUUID, let sessionDescription):
                try dataPayloadContainer.encode("offer", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString.lowercased(), forKey: .toId)

                let wrapperSession = SessionDescription(from: sessionDescription)
                try dataPayloadContainer.encode(wrapperSession, forKey: .data)
            case .sdpAnswer(let workerUUID, let scopeUUID, let toUUID, let sessionDescription):
                try dataPayloadContainer.encode("answer", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString.lowercased(), forKey: .toId)

                let wrapperSession = SessionDescription(from: sessionDescription)
                try dataPayloadContainer.encode(wrapperSession, forKey: .data)
            case .iceCandidate(let workerUUID, let scopeUUID, let toUUID, let iceCandidate):
                try dataPayloadContainer.encode("candidate", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString.lowercased(), forKey: .toId)

                let wrappedCandidate = IceCandidate(from: iceCandidate)
                try dataPayloadContainer.encode(wrappedCandidate, forKey: .data)
            }
        default:
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Invalid type to encode"))
        }
    }
}

extension SignallingMessagesResponse: Codable {

    // swiftlint:disable function_body_length
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .getProtocolRequest(let workerUUID, let scopeUUID, let protocolId):
            try container.encode("get-protocol", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
            try dataPayloadContainer.encode(protocolId, forKey: .protocolId)
        case .joinRoom(let workerUUID, let scopeUUID):
            try container.encode("webrtc: join-room", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
        case .webRTCPeerLeft(let workerUUID, let scopeUUID):
            try container.encode("webrtc: peer-left", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
        case .webRTCInternalMessage(let webRTCInternalMessage):
            try container.encode("webrtc: internal-message", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: WebRTCInternalMessage.CodingKeys.self,
                                                                 forKey: .data)
            switch webRTCInternalMessage {
            case .sdpOffer(let workerUUID, let scopeUUID, let toUUID, let sessionDescription):
                try dataPayloadContainer.encode("offer", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString.lowercased(), forKey: .toId)

                let wrapperSession = SessionDescription(from: sessionDescription)
                try dataPayloadContainer.encode(wrapperSession, forKey: .data)
            case .sdpAnswer(let workerUUID, let scopeUUID, let toUUID, let sessionDescription):
                try dataPayloadContainer.encode("answer", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString.lowercased(), forKey: .toId)

                let wrapperSession = SessionDescription(from: sessionDescription)
                try dataPayloadContainer.encode(wrapperSession, forKey: .data)
            case .iceCandidate(let workerUUID, let scopeUUID, let toUUID, let iceCandidate):
                try dataPayloadContainer.encode("candidate", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString.lowercased(), forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString.lowercased(), forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString.lowercased(), forKey: .toId)

                let wrappedCandidate = IceCandidate(from: iceCandidate)
                try dataPayloadContainer.encode(wrappedCandidate, forKey: .data)
            }
        default:
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Invalid type to encode"))
        }
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "federated/authenticate" {

            let authenticationContainer = try container.nestedContainer(keyedBy: AuthenticationCodingKeys.self, forKey: .data)
            if let workerId = try authenticationContainer.decodeIfPresent(String.self, forKey: .workerId),
                let workerUUID = UUID(uuidString: workerId) {
                self = .authRequestResponse(.success(workerUUID))
            } else if let errorString = try authenticationContainer.decodeIfPresent(String.self, forKey: .error) {
                self = .authRequestResponse(.failure(AuthenticationError(message: errorString)))
            } else {
                self = .authRequestResponse(.failure(AuthenticationError(message: "Unknown Authentication Error")))
            }

        } else if type == "get-protocol" {

            self = .getProtocolResponse

        } else if type == "webrtc: join-room" {

            let dataContainer = try container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            let workerId = try dataContainer.decode(String.self, forKey: .workerId)
            let scopeId = try dataContainer.decode(String.self, forKey: .scopeId)
            if let workerUUID = UUID(uuidString: workerId),
                let scopeUUID = UUID(uuidString: scopeId) {
                self = .joinRoom(workerId: workerUUID, scopeId: scopeUUID)
            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else if type == "webrtc: peer-left" {

            let dataContainer = try container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            let workerId = try dataContainer.decode(String.self, forKey: .workerId)
            let scopeId = try dataContainer.decode(String.self, forKey: .workerId)
            if let workerUUID = UUID(uuidString: workerId),
                let scopeUUID = UUID(uuidString: scopeId) {
                self = .webRTCPeerLeft(workerId: workerUUID, scopeId: scopeUUID)
            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else if type == "webrtc: internal-message" {

            self = .webRTCInternalMessage(try container.decode(WebRTCInternalMessage.self, forKey: .data))

        } else {
            throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                         debugDescription: "Invalid type value"))
        }
    }
}

extension WebRTCInternalMessage: Equatable {
    static func == (lhs: WebRTCInternalMessage, rhs: WebRTCInternalMessage) -> Bool {
        switch (lhs, rhs) {
        case (let .sdpOffer(lhsWorkerUUID, lhsScopeUUID, lhsToUUID, lhsSessionDescription), let .sdpOffer(rhsWorkerUUID, rhsScopeUUID, rhsToUUID, rhsSessionDescription)):
            return (lhsWorkerUUID, lhsScopeUUID, lhsToUUID, lhsSessionDescription.sdp) == (rhsWorkerUUID, rhsScopeUUID, rhsToUUID, rhsSessionDescription.sdp)
        case (let .sdpAnswer(lhsWorkerUUID, lhsScopeUUID, lhsToUUID, lhsSessionDescription), let .sdpAnswer(rhsWorkerUUID, rhsScopeUUID, rhsToUUID, rhsSessionDescription)):
            return (lhsWorkerUUID, lhsScopeUUID, lhsToUUID, lhsSessionDescription.sdp) == (rhsWorkerUUID, rhsScopeUUID, rhsToUUID, rhsSessionDescription.sdp)
        case (let .iceCandidate(lhsWorkerUUID, lhsScopeUUID, lhsToUUID, lhsIceCandidate), let .iceCandidate(rhsWorkerUUID, rhsScopeUUID, rhsToUUID, rhsIceCandidate)):
            return (lhsWorkerUUID, lhsScopeUUID, lhsToUUID, lhsIceCandidate.sdp) == (rhsWorkerUUID, rhsScopeUUID, rhsToUUID, rhsIceCandidate.sdp)
        default:
            return false
        }
    }
}

extension SignallingMessagesRequest: Equatable {
    static func == (lhs: SignallingMessagesRequest, rhs: SignallingMessagesRequest) -> Bool {
        switch (lhs, rhs) {
        case (let .webRTCPeerLeft(lhsWorkerUUID, lhsScopeUUID), let .webRTCPeerLeft(rhsWorkerUUID, rhsScopeUUID)):
            return (lhsWorkerUUID, lhsScopeUUID) == (rhsWorkerUUID, rhsScopeUUID)
        case (let .joinRoom(lhsWorkerUUID, lhsScopeUUID), let .joinRoom(rhsWorkerUUID, rhsScopeUUID)):
            return (lhsWorkerUUID, lhsScopeUUID) == (rhsWorkerUUID, rhsScopeUUID)
        case (let .webRTCInternalMessage(lhsInternalMessage), let .webRTCInternalMessage(rhsInternalMessage)):
            return lhsInternalMessage == rhsInternalMessage
        case (.getProtocolResponse, .getProtocolResponse):
            return true
        case (let .getProtocolRequest(lhsWorkerUUID, lhsScopeUUID, lhsProtocolID), let .getProtocolRequest(rhsWorkerUUID, rhsScopeUUID, rhsProtocolId)):
            return (lhsWorkerUUID, lhsScopeUUID, lhsProtocolID) == (rhsWorkerUUID, rhsScopeUUID, rhsProtocolId)
        default:
            return false
        }
    }
}

extension SignallingMessagesResponse: Equatable {
    static func == (lhs: SignallingMessagesResponse, rhs: SignallingMessagesResponse) -> Bool {
        switch (lhs, rhs) {
        case (let .webRTCPeerLeft(lhsWorkerUUID, lhsScopeUUID), let .webRTCPeerLeft(rhsWorkerUUID, rhsScopeUUID)):
            return (lhsWorkerUUID, lhsScopeUUID) == (rhsWorkerUUID, rhsScopeUUID)
        case (let .joinRoom(lhsWorkerUUID, lhsScopeUUID), let .joinRoom(rhsWorkerUUID, rhsScopeUUID)):
            return (lhsWorkerUUID, lhsScopeUUID) == (rhsWorkerUUID, rhsScopeUUID)
        case (let .webRTCInternalMessage(lhsInternalMessage), let .webRTCInternalMessage(rhsInternalMessage)):
            return lhsInternalMessage == rhsInternalMessage
        case (.getProtocolResponse, .getProtocolResponse):
            return true
        case (let .getProtocolRequest(lhsWorkerUUID, lhsScopeUUID, lhsProtocolID), let .getProtocolRequest(rhsWorkerUUID, rhsScopeUUID, rhsProtocolId)):
            return (lhsWorkerUUID, lhsScopeUUID, lhsProtocolID) == (rhsWorkerUUID, rhsScopeUUID, rhsProtocolId)
        default:
            return false
        }
    }
}
