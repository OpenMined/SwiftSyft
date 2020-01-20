//
//  SignalingClientProtocol.swift
//  Pods-SwiftSyft_Example
//
//  Created by Mark Jeremiah Jimenez on 20/01/2020.
//

import Foundation

/// Holds web socket conection logic. Handles socket message serialization/deserialization
protocol SignallingClientProtocol {
    init(url: SocketClientProtocol)

    func connect()
    func send()

}
