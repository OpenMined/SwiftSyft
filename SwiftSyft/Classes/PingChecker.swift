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



