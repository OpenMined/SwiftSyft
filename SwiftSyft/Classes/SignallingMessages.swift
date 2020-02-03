import WebRTC
import Foundation

enum SignallingMessages {
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
    }
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
}

extension WebRTCInternalMessage: Codable {

    // swiftlint:disable function_body_length
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "offer" {
            let workerId = try container.decode(String.self, forKey: .workerId)
            let scopeId = try container.decode(String.self, forKey: .scopeId)
            let toId = try container.decode(String.self, forKey: .toId)
            let data = try container.decode(String.self, forKey: .data)
            if let workerUUID = UUID(uuidString: workerId),
                let scopeUUID = UUID(uuidString: scopeId),
                let toId =  UUID(uuidString: toId) {

                self = .sdpOffer(workerId: workerUUID,
                                 scopeId: scopeUUID,
                                 toId: toId,
                                 sdp: RTCSessionDescription(type: .offer, sdp: data))

            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else if type == "answer" {

            let workerId = try container.decode(String.self, forKey: .workerId)
            let scopeId = try container.decode(String.self, forKey: .scopeId)
            let toId = try container.decode(String.self, forKey: .toId)
            let data = try container.decode(String.self, forKey: .data)
            if let workerUUID = UUID(uuidString: workerId),
               let scopeUUID = UUID(uuidString: scopeId),
               let toId =  UUID(uuidString: toId) {

                self = .sdpAnswer(workerId: workerUUID,
                                  scopeId: scopeUUID,
                                  toId: toId,
                                  sdp: RTCSessionDescription(type: .answer, sdp: data))

            } else {
                throw EncodingError.invalidValue(type, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                             debugDescription: "Invalid payload keys"))
            }

        } else if type == "candidate" {

            let workerId = try container.decode(String.self, forKey: .workerId)
            let scopeId = try container.decode(String.self, forKey: .scopeId)
            let toId = try container.decode(String.self, forKey: .toId)
            let data = try container.decode(String.self, forKey: .data)
            if let workerUUID = UUID(uuidString: workerId),
               let scopeUUID = UUID(uuidString: scopeId),
               let toId =  UUID(uuidString: toId) {

                let iceCandidate = RTCIceCandidate(sdp: data, sdpMLineIndex: -1, sdpMid: nil)
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

    func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sdpOffer(let workerUUID, let scopeUUID, let toUUID, let rtcSessionDescription):
            try container.encode("offer", forKey: .type)
            try container.encode(workerUUID.uuidString, forKey: .workerId)
            try container.encode(scopeUUID.uuidString, forKey: .scopeId)
            try container.encode(toUUID.uuidString, forKey: .toId)
            try container.encode(rtcSessionDescription.sdp, forKey: .data)
        case .sdpAnswer(let workerUUID, let scopeUUID, let toUUID, let rtcSessionDescription):
            try container.encode("answer", forKey: .type)
            try container.encode(workerUUID.uuidString, forKey: .workerId)
            try container.encode(scopeUUID.uuidString, forKey: .scopeId)
            try container.encode(toUUID.uuidString, forKey: .toId)
            try container.encode(rtcSessionDescription.sdp, forKey: .data)
        case .iceCandidate(let workerUUID, let scopeUUID, let toUUID, let iceCandidate):
            try container.encode("canddidate", forKey: .type)
            try container.encode(workerUUID.uuidString, forKey: .workerId)
            try container.encode(scopeUUID.uuidString, forKey: .scopeId)
            try container.encode(toUUID.uuidString, forKey: .toId)
            try container.encode(iceCandidate.sdp, forKey: .data)
        }
    }
    // swiftlint:enable function_body_length

}

extension SignallingMessages: Codable {

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "webrtc: join-room" {

            let dataContainer = try container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            let workerId = try dataContainer.decode(String.self, forKey: .workerId)
            let scopeId = try dataContainer.decode(String.self, forKey: .workerId)
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .joinRoom(let workerUUID, let scopeUUID):
            try container.encode("webrtc: join-room", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString, forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString, forKey: .scopeId)
        case .webRTCPeerLeft(let workerUUID, let scopeUUID):
            try container.encode("webrtc: peer-left", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: DataPayloadCodingKeys.self, forKey: .data)
            try dataPayloadContainer.encode(workerUUID.uuidString, forKey: .workerId)
            try dataPayloadContainer.encode(scopeUUID.uuidString, forKey: .scopeId)
        case .webRTCInternalMessage(let webRTCInternalMessage):
            try container.encode("webrtc: internal-message", forKey: .type)
            var dataPayloadContainer = container.nestedContainer(keyedBy: WebRTCInternalMessage.CodingKeys.self,
                                                                 forKey: .data)
            switch webRTCInternalMessage {
            case .sdpOffer(let workerUUID, let scopeUUID, let toUUID, let sessionDescription):
                try dataPayloadContainer.encode("offer", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString, forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString, forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString, forKey: .toId)
                try dataPayloadContainer.encode(sessionDescription.sdp, forKey: .data)
            case .sdpAnswer(let workerUUID, let scopeUUID, let toUUID, let sessionDescription):
                try dataPayloadContainer.encode("answer", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString, forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString, forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString, forKey: .toId)
                try dataPayloadContainer.encode(sessionDescription.sdp, forKey: .data)
            case .iceCandidate(let workerUUID, let scopeUUID, let toUUID, let iceCandidate):
                try dataPayloadContainer.encode("candidate", forKey: .type)
                try dataPayloadContainer.encode(workerUUID.uuidString, forKey: .workerId)
                try dataPayloadContainer.encode(scopeUUID.uuidString, forKey: .scopeId)
                try dataPayloadContainer.encode(toUUID.uuidString, forKey: .toId)
                try dataPayloadContainer.encode(iceCandidate.sdp, forKey: .data)
            }
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

extension SignallingMessages: Equatable {
    static func == (lhs: SignallingMessages, rhs: SignallingMessages) -> Bool {
        switch (lhs, rhs) {
        case (let .webRTCPeerLeft(lhsWorkerUUID, lhsScopeUUID), let .webRTCPeerLeft(rhsWorkerUUID, rhsScopeUUID)):
            return (lhsWorkerUUID, lhsScopeUUID) == (rhsWorkerUUID, rhsScopeUUID)
        case (let .joinRoom(lhsWorkerUUID, lhsScopeUUID), let .joinRoom(rhsWorkerUUID, rhsScopeUUID)):
            return (lhsWorkerUUID, lhsScopeUUID) == (rhsWorkerUUID, rhsScopeUUID)
        case (let .webRTCInternalMessage(lhsInternalMessage), let .webRTCInternalMessage(rhsInternalMessage)):
            return lhsInternalMessage == rhsInternalMessage
        default:
            return false
        }
    }
}
