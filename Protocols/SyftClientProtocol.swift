//
//  SyftProtocol.swift
//  Pods-SwiftSyft_Example
//
//  Created by Mark Jeremiah Jimenez on 20/01/2020.
//

import Foundation

/// Describes interface for syft client that coordinates signalling and peer-to-peer connection
protocol SyftClientProtocol {
    var workerId: String? { get set }
    var scopeId: String? { get set }
    var signallingClient: SignallingClientProtocol { get set}
}
