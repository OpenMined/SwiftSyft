//
//  File.swift
//  Pods-SwiftSyft_Example
//
//  Created by Mark Jeremiah Jimenez on 20/01/2020.
//

import Foundation

/// Wrapper over any websocket client provider
protocol SocketClientProtocol {

    init(url: URL)

    var delegate: SocketClientDelegate? { get set }
    func connect()
    func disconnect()
    func send(data: Data)
}

/// Receive connection events from
protocol SocketClientDelegate {
    func didConnect(_ socketClient: SocketClientProtocol)
    func didDisconnect(_ socketClient: SocketClientProtocol)
}
