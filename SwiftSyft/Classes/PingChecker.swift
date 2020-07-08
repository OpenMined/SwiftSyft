import Foundation
import Combine

internal typealias PingCheckerCallback = (UInt16?) -> Void

internal class PingChecker: NSObject {
    static let singletonPingChecker = PingChecker()

    private var pingResultCallback: PingCheckerCallback?
    private var simplePingClient: SimplePing?
    private var referenceDate: Date?

    /// This method checks the latency between the device and a hostname.
    ///
    /// - Important: The latency is computed in miliseconds (ms).
    ///
    /// - parameters:
    ///     - hostname: The hostname to ping. It can be a domain or an IP Address.
    ///     - resultCallback: The result callback. Check PingCheckerCallback for the callback type.
    static func pingHostname(hostname: String, resultCallback callback: PingCheckerCallback?) {
        singletonPingChecker.pingHostname(hostname: hostname, resultCallback: callback)
    }
    /// This method checks the latency between the device and a hostname.
    ///
    ///  The code was written with the help of: https://www.vadimbulavin.com/asynchronous-programming-with-future-and-promise-in-swift-with-combine-framework/
    /// - Important: The latency is computed in miliseconds (ms).
    ///
    /// - parameters:
    ///     - hostname: The hostname to ping. It can be a domain or an IP Address.
    /// - returns:
    ///   A publisher that produces one UInt16 value or fails if the hostname is unreachable.
    static func pingHostname(hostname: String) -> Future<UInt16, Error> {
         let pingFuture = Future<UInt16, Error> { promise in
                 pingHostname(hostname: hostname) { latency in
                     guard let latencyMS = latency else {
                         promise(.failure(PingCheckerError.networkUnreachable))
                         return
                     }
                     promise(.success(latencyMS))
                 }
         }
         return pingFuture
     }
    private func pingHostname(hostname: String, resultCallback callback: PingCheckerCallback?) {
        pingResultCallback = callback
        simplePingClient = SimplePing(hostName: hostname)
        simplePingClient?.delegate = self
        simplePingClient?.start()
    }
}

extension PingChecker: SimplePingDelegate {
    // Simple Ping delegate methods
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        pinger.send(with: nil)
    }
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        pingResultCallback?(nil)
    }

    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        referenceDate = Date()
    }

    func simplePing(pinger: SimplePing!, _ didFailToSendPacket: NSData!, error: NSError!) {
        pinger.stop()
        pingResultCallback?(nil)
    }

    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        pinger.stop()
        pingResultCallback?(nil)
    }

    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
       pinger.stop()
       guard let referencedate = referenceDate else { return }
       let latency = UInt16(Date().timeIntervalSince(referencedate) * 1000)
       pingResultCallback?(UInt16(latency))
    }
    enum PingCheckerError: Error {
        case networkUnreachable
    }
}
