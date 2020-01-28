//
//  SyftWebSocket.swift
//  SwiftSyft
//
//  Created by Sasha Bataieva on 25/01/2020.
//

import Foundation
import Starscream

public enum WSEventType {
    case connected
    case disconnected
    case text(String)
    case binary(Data)
    case error(Error?)
    case cancelled
}

public class SyftWebSocket: SocketClientProtocol {
    weak var delegate: SocketClientDelegate?
    public weak var socketDelegate: WSDelegate?
    var url: URL?
    var pingInterval: Double?

    public var callbackQueue = DispatchQueue.main

    // MARK: - SocketClientProtocol
    required public init(url: URL, pingInterval: Double) {
        self.url = url
        self.pingInterval = pingInterval
    }

    public func connect() {
        didReceive(event: WSEventType.connected)
    }

    public func disconnect() {
        didReceive(event: WSEventType.disconnected)
    }

    func send(data: Data) {
        didReceive(event: WSEventType.binary(data))
    }

    public func sendText(text: String) {
        didReceive(event: WSEventType.text(text))
    }

    // MARK: - Delegate
    public func didReceive(event: WSEventType) {
        callbackQueue.async { [weak self] in
            guard let selfObject = self else { return }
            selfObject.socketDelegate?.didReceive(event: event)
        }
    }
}

public protocol WSDelegate: class {
    func didReceive(event: WSEventType)
}
