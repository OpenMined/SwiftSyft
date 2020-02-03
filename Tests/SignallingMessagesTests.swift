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

extension SignallingMessages: JSONTestable { }

class SignallingMessagesTests: XCTestCase {

    private let joinRoomJSON = """
{"type":"webrtc: join-room","data":{"workerId":"1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED","scopeId":"F0BE538D-E185-47CC-AC68-27EC26088BA6"}}
"""

    private let webrtcPeerLeftJSON = """
{"type":"webrtc: peer-left","data":{"workerId":"1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED","scopeId":"F0BE538D-E185-47CC-AC68-27EC26088BA6"}}
"""

    private let webrtcOfferJSON = """
{"type":"webrtc: internal-message","data":{"scopeId":"F0BE538D-E185-47CC-AC68-27EC26088BA6","to":"5B06F42E-EE96-43E6-A6E7-E24F5A21268B","data":"SDP_OFFER","type":"offer","workerId":"1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED"}}
"""

    private let webrtcAnswerJSON = """
{"type":"webrtc: internal-message","data":{"scopeId":"F0BE538D-E185-47CC-AC68-27EC26088BA6","to":"5B06F42E-EE96-43E6-A6E7-E24F5A21268B","data":"SDP_ANSWER","type":"answer","workerId":"1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED"}}
"""
    private let webrtcIceCandidateJSON = """
{"type":"webrtc: internal-message","data":{"scopeId":"F0BE538D-E185-47CC-AC68-27EC26088BA6","to":"5B06F42E-EE96-43E6-A6E7-E24F5A21268B","data":"SDP_CANDIDATE","type":"candidate","workerId":"1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED"}}
"""

    func testJoinRoomJSON() {

        let joinRoom = SignallingMessages.joinRoom(workerId: UUID(uuidString: "1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED")!, scopeId: UUID(uuidString: "F0BE538D-E185-47CC-AC68-27EC26088BA6")!)

        XCTAssertEqual(joinRoomJSON, joinRoom.json())
    }

    func testWebrtcPeerLeftJSON() {

        let peerLeft = SignallingMessages.webRTCPeerLeft(workerId: UUID(uuidString: "1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED")!, scopeId: UUID(uuidString: "F0BE538D-E185-47CC-AC68-27EC26088BA6")!)

        XCTAssertEqual(webrtcPeerLeftJSON, peerLeft.json())
    }

    func testWebrtcOfferJSON() {

        let offerJSON = SignallingMessages.webRTCInternalMessage(.sdpOffer(workerId: UUID(uuidString: "1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED")!, scopeId: UUID(uuidString: "F0BE538D-E185-47CC-AC68-27EC26088BA6")!, toId: UUID(uuidString: "5B06F42E-EE96-43E6-A6E7-E24F5A21268B")!, sdp: RTCSessionDescription(type: .offer, sdp: "SDP_OFFER")))

        XCTAssertEqual(webrtcOfferJSON, offerJSON.json())

    }

    func testWebrtcAnswerJSON() {
        let offerJSON = SignallingMessages.webRTCInternalMessage(.sdpAnswer(workerId: UUID(uuidString: "1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED")!, scopeId: UUID(uuidString: "F0BE538D-E185-47CC-AC68-27EC26088BA6")!, toId: UUID(uuidString: "5B06F42E-EE96-43E6-A6E7-E24F5A21268B")!, sdp: RTCSessionDescription(type: .offer, sdp: "SDP_ANSWER")))

        XCTAssertEqual(webrtcAnswerJSON, offerJSON.json())

    }

    func testWebrtcIceCandidateJSON() {

        let offerJSON = SignallingMessages.webRTCInternalMessage(.iceCandidate(workerId: UUID(uuidString: "1B9D6BCD-BBFD-4B2D-9B5D-AB8DFBBD4BED")!, scopeId: UUID(uuidString: "F0BE538D-E185-47CC-AC68-27EC26088BA6")!, toId: UUID(uuidString: "5B06F42E-EE96-43E6-A6E7-E24F5A21268B")!, sdp: RTCIceCandidate(sdp: "SDP_CANDIDATE", sdpMLineIndex: -1, sdpMid: nil)))

        XCTAssertEqual(webrtcIceCandidateJSON, offerJSON.json())


    }
}

