//
//  File.swift
//  Pods-SwiftSyft_Example
//
//  Created by Mark Jeremiah Jimenez on 20/01/2020.
//

import Foundation

/// Wrapper over any websocket client provider
protocol SocketClientProtocol {

    init(url: URL, pingInterval: Double)

    var delegate: SocketClientDelegate? { get set }
    func connect()
    func disconnect()
    func send(data: Data)
}

/// Receive connection events from
protocol SocketClientDelegate: class {
    func didConnect(_ socketClient: SocketClientProtocol)
    func didDisconnect(_ socketClient: SocketClientProtocol)
    func didReceive(socketMessage result: Result<Data, Error>)
}
