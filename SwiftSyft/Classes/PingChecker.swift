import Foundation

public typealias PingCheckerCallback = (UInt16?)->()

public class PingChecker: NSObject {
    static let singletonPingChecker = PingChecker()

    private var pingResultCallback: PingCheckerCallback?
    private var simplePingClient: SimplePing?
    private var referenceDate: Date?

    public static func pingHostname(hostname: String, andResultCallback callback: PingCheckerCallback?) {
        singletonPingChecker.pingHostname(hostname: hostname, andResultCallback: callback)
    }

    public func pingHostname(hostname: String, andResultCallback callback: PingCheckerCallback?) {
        pingResultCallback = callback
        simplePingClient = SimplePing(hostName: hostname)
        simplePingClient?.delegate = self
        simplePingClient?.start()
    }
}

extension PingChecker: SimplePingDelegate {
    // Simple Ping delegate methods
    public func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        pinger.send(with: nil)
    }
    public func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        pingResultCallback?(nil)
    }

    public func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        referenceDate = Date()
    }

    public func simplePing(pinger: SimplePing!, _ didFailToSendPacket: NSData!, error: NSError!) {
        pinger.stop()
        pingResultCallback?(nil)
    }

    public func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        pinger.stop()
        pingResultCallback?(nil)
    }

    public func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
       pinger.stop()
       guard let referencedate = referenceDate else { return }
       let latency = UInt16(Date().timeIntervalSince(referencedate) * 1000)
       pingResultCallback?(UInt16(latency))
    }
}
