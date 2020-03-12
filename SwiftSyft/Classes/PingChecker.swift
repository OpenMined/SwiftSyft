//
//  PingChecker.swift
//  Pods
//
//  Created by Madalin Mamuleanu on 07/03/2020.
//


import Foundation

public class PingChecker: NSObject {
    
    static let singletonPingChecker = PingChecker()

    private var pingResultCallback: (String?)->()?
    private var simplePingClient: SimplePing?
    private var referenceDate: Date?

    public static func pingHostname(hostname: String, andResultCallback callback: (String?)->()?) {
        singletonPingChecker.pingHostname(hostname: hostname, andResultCallback: callback)
    }

    public func pingHostname(hostname: String, andResultCallback callback: (String?)->()?) {
        resultCallback = callback
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
        resultCallback?(nil)
    }

    public func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        dateReference = Date()
    }

    public func simplePing(pinger: SimplePing!, _ didFailToSendPacket: NSData!, error: NSError!) {
        pinger.stop()
        resultCallback?(nil)
    }

    public func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        pinger.stop()
        resultCallback?(nil)
    }

    public func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
          pinger.stop()
          guard let reference_date = referenceDate else { return }
          //timeIntervalSinceDate returns seconds, so we convert to milis
          let latency = Date().timeIntervalSince(reference_date) * 1000
          resultCallback?(String(format: "%.f", latency))
    }
}

