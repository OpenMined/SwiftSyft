//
//  SyftWebSocket.swift
//  SwiftSyft
//
//  Created by Sasha Bataieva on 25/01/2020.
//

import Foundation
import Starscream

public class SyftWebSocketIOS12: SyftWebSocket, WebSocketDelegate {
    var client: WebSocket?

    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        self.client = client
        switch event {
        case .connected(let headers):
            connected()
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            disconnect()
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

    var socket: WebSocket!
    let server = WebSocketServer()

    // MARK: - SocketClientProtocol
    required public init(url: URL, pingInterval: Double) {
        super.init(url: url, pingInterval: pingInterval)
    }

    override public func connect() {
        socket = WebSocket(request: URLRequest(url: self.url!))
        socket.delegate = self
        socket.connect()
    }

    func connected() {
        didReceive(event: SyftWebSocketEvent.connected)
    }

    override public func disconnect() {
        socket.disconnect()
        socket.delegate = nil
        didReceive(event: SyftWebSocketEvent.disconnected)
    }

    override func send(data: Data) {
        socket.write(data: data, completion: nil)
        
    }

    override public func sendText(text: String) {
        socket.write(string: text)
    }
}
