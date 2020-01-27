//
//  SyftWebSocket.swift
//  SwiftSyft
//
//  Created by Sasha Bataieva on 25/01/2020.
//

import Foundation
import Starscream

public enum SyftWebSocketEvent {
    case connected
    case disconnected
    case text(String)
    case binary(Data)
    case error(Error?)
    case cancelled
}

public class SyftWebSocket: SocketClientProtocol {
    var delegate: SocketClientDelegate?
    public weak var socketDelegate: SyftWebSocketDelegate?
    var url: URL?
    var pingInterval: Double?
    public var callbackQueue = DispatchQueue.main

    // MARK: - SocketClientProtocol
    required public init(url: URL, pingInterval: Double) {
        self.url = url
        self.pingInterval = pingInterval
    }

    public func connect() {
        didReceive(event: SyftWebSocketEvent.connected)
    }

    public func disconnect() {
        didReceive(event: SyftWebSocketEvent.disconnected)
    }

    func send(data: Data) {
        didReceive(event: SyftWebSocketEvent.binary(data))
    }

    public func sendText(text: String) {
        didReceive(event: SyftWebSocketEvent.text(text))
    }

    // MARK: - Delegate
    public func didReceive(event: SyftWebSocketEvent) {
        callbackQueue.async { [weak self] in
            guard let s11 = self else { return }
            s11.socketDelegate?.didReceive(event: event)
        }
    }
}

public protocol SyftWebSocketDelegate: class {
    func didReceive(event: SyftWebSocketEvent)
}
