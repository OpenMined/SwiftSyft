//
//  SyftWebSocket_iOS13.swift
//  Pods-SwiftSyft_Example
//
//  Created by Madalin Mamuleanu on 03/02/2020.
//

import Foundation

@available(iOS 13.0, *)
class SyftWebSocket: NSObject, SocketClientProtocol, URLSessionWebSocketDelegate {

    weak var delegate: SocketClientDelegate?
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    let delegateQueue = OperationQueue()
    required init(url: URL, pingInterval: Double) {
        super.init()
        #if !DEBUG
        guard url.absoluteString.hasPrefix("wss") else {
            preconditionFailure("Path for socket server should start with wss://")
        }
        #endif
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: url)
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.delegate?.didConnect(self)
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.delegate?.didDisconnect(self)
    }
    func connect() {
        webSocketTask.resume()
        listen()
    }
    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    func listen() {
        webSocketTask.receive { [weak self] result in
            switch result {
            case .failure(let error):
                #if DEBUG
                print("websocket encountered an error: \(error)")
                #endif
            case .success(let message):
                switch message {
                case .string(let text):
                    guard let data = text.data(using: .utf8) else {
                        break
                    }
                    self?.delegate?.didReceive(socketMessage: .success(data))
                    #if DEBUG
                    print("Received text: \(text)")
                    #endif
                case .data(let data):
                    self?.delegate?.didReceive(socketMessage: .success(data))
                    #if DEBUG
                    print("Received data: \(data.count)")
                    #endif
                @unknown default:
                    fatalError()
                }
                self?.listen()
            }
        }
    }
    func send(text: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error = error {
                #if DEBUG
                print("websocket encountered an error: \(error)")
                #endif
            }
        }
    }
    func sendText(text: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error = error {
                #if DEBUG
                print("websocket encountered an error: \(error)")
                #endif
            }
        }
    }
    func send(data: Data) {
        webSocketTask.send(URLSessionWebSocketTask.Message.data(data)) { error in
            if let error = error {
                #if DEBUG
                print("websocket encountered an error: \(error)")
                #endif
            }
        }
    }
}
