//
//  SyftWebSocket.swift
//  SwiftSyft
//
//  Created by Sasha Bataieva on 25/01/2020.
//

import Foundation
import Starscream

public class SyftWebSocketIOS12: SocketClientProtocol, WebSocketDelegate {
    public weak var delegate: SocketClientDelegate?
    let socket: WebSocket

    // MARK: - WebSocketDelegate
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            self.delegate?.didConnect(self)
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            self.delegate?.didDisconnect(self)
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            sendText(text: string)
            print("Received text: \(string)")
        case .binary(let data):
            send(data: data)
            print("Received data: \(data.count)")
        case .cancelled:
            disconnect()
        case .error(let error):
            handleError(error)
        default: // ping, pong, viablityChanged, reconnectSuggested
            break
        }
    }

    func handleError(_ error: Error?) {
        if let err = error as? WSError {
            print("websocket encountered an error: \(err.message)")
        } else if let err = error {
            print("websocket encountered an error: \(err.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }

    // MARK: - SocketClientProtocol
    required public init(url: URL, pingInterval: Double) {
        guard url.absoluteString.hasPrefix("wss") else {
            preconditionFailure("Path for socket server shoud start with wss://")
        }
        socket = WebSocket(request: URLRequest(url: url))
        socket.delegate = self
    }

    public func connect() {
        socket.connect()
    }

    public func disconnect() {
        socket.disconnect()
        socket.delegate = nil
    }

    public func send(data: Data) {
        socket.write(data: data)
    }

    public func sendText(text: String) {
        socket.write(string: text)
    }
}
