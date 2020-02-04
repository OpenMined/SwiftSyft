//
//  SignalingClientProtocol.swift
//  Pods-SwiftSyft_Example
//
//  Created by Mark Jeremiah Jimenez on 20/01/2020.
//

import Foundation

/// Holds web socket conection logic. Handles socket message serialization/deserialization
protocol SignallingClientProtocol {

    func connect()
    func disconnect()
    func send(_ message: SignallingMessages) throws

}

protocol SignallingClientDelegate: class {
    func didReceive(_ message: SignallingMessages)
}
