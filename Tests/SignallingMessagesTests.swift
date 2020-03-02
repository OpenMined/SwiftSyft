import XCTest
@testable import SwiftSyft
import WebRTC

protocol JSONTestable {
    init?(_ json: String)
    func json() -> String?
}

extension JSONTestable where Self: Codable {
    init?(_ json: String) {
        guard
            let data = json.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(Self.self, from: data)
            else { return nil }
        self = decoded
    }

    func json() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension SignallingMessagesResponse: JSONTestable { }

class SignallingMessagesTests: XCTestCase {

    private let joinRoomJSON = """
{"type":"webrtc: join-room","data":{"workerId":"1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed","scopeId":"f0be538d-e185-47cc-ac68-27ec26088ba6"}}
"""

    private let webrtcPeerLeftJSON = """
{"type":"webrtc: peer-left","data":{"workerId":"1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed","scopeId":"f0be538d-e185-47cc-ac68-27ec26088ba6"}}
"""

    private let webrtcOfferJSON = """
{"type":"webrtc: internal-message","data":{"scopeId":"f0be538d-e185-47cc-ac68-27ec26088ba6","to":"5b06f42e-ee96-43e6-a6e7-e24f5a21268b","data":{"sdp":"SDP_OFFER","type":"offer"},"type":"offer","workerId":"1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed"}}
"""

    private let webrtcAnswerJSON = """
{"type":"webrtc: internal-message","data":{"scopeId":"f0be538d-e185-47cc-ac68-27ec26088ba6","to":"5b06f42e-ee96-43e6-a6e7-e24f5a21268b","data":{"sdp":"SDP_ANSWER","type":"offer"},"type":"answer","workerId":"1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed"}}
"""

    private let webrtcIceCandidateJSON = """
{"type":"webrtc: internal-message","data":{"scopeId":"f0be538d-e185-47cc-ac68-27ec26088ba6","to":"5b06f42e-ee96-43e6-a6e7-e24f5a21268b","data":{"sdpMLineIndex":-1,"candidate":"SDP_CANDIDATE"},"type":"candidate","workerId":"1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed"}}
"""

    func testJoinRoomJSON() {

        let joinRoom = SignallingMessagesResponse.joinRoom(workerId: UUID(uuidString: "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed")!, scopeId: UUID(uuidString: "f0be538d-e185-47cc-ac68-27ec26088ba6")!)

        XCTAssertEqual(joinRoomJSON, joinRoom.json())
    }

    func testWebrtcPeerLeftJSON() {

        let peerLeft = SignallingMessagesResponse.webRTCPeerLeft(workerId: UUID(uuidString: "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed")!, scopeId: UUID(uuidString: "f0be538d-e185-47cc-ac68-27ec26088ba6")!)

        XCTAssertEqual(webrtcPeerLeftJSON, peerLeft.json())
    }

    func testWebrtcOfferJSON() {

        let offerJSON = SignallingMessagesResponse.webRTCInternalMessage(.sdpOffer(workerId: UUID(uuidString: "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed")!, scopeId: UUID(uuidString: "f0be538d-e185-47cc-ac68-27ec26088ba6")!, toId: UUID(uuidString: "5b06f42e-ee96-43e6-a6e7-e24f5a21268b")!, sdp: RTCSessionDescription(type: .offer, sdp: "SDP_OFFER")))

        XCTAssertEqual(webrtcOfferJSON, offerJSON.json())

    }

    func testWebrtcAnswerJSON() {
        let offerJSON = SignallingMessagesResponse.webRTCInternalMessage(.sdpAnswer(workerId: UUID(uuidString: "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed")!, scopeId: UUID(uuidString: "f0be538d-e185-47cc-ac68-27ec26088ba6")!, toId: UUID(uuidString: "5b06f42e-ee96-43e6-a6e7-e24f5a21268b")!, sdp: RTCSessionDescription(type: .offer, sdp: "SDP_ANSWER")))

        XCTAssertEqual(webrtcAnswerJSON, offerJSON.json())

    }

    func testWebrtcIceCandidateJSON() {

        let offerJSON = SignallingMessagesResponse.webRTCInternalMessage(.iceCandidate(workerId: UUID(uuidString: "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed")!, scopeId: UUID(uuidString: "f0be538d-e185-47cc-ac68-27ec26088ba6")!, toId: UUID(uuidString: "5b06f42e-ee96-43e6-a6e7-e24f5a21268b")!, sdp: RTCIceCandidate(sdp: "SDP_CANDIDATE", sdpMLineIndex: -1, sdpMid: nil)))

        XCTAssertEqual(webrtcIceCandidateJSON, offerJSON.json())


    }
}

