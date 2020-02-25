//
//  HomeViewController.swift
//  SwiftSyft
//
//  Created by SashaBataieva on 01/20/2020.
//  Copyright (c) 2020 mjjimenez. All rights reserved.
//

import UIKit
import SwiftSyft

enum StaticHomeScreenStrings {
    static let headerDescription = "syft.js/grid.js testing"
    static let description = """
            This is a demo using @SwiftSyft@ from @OpenMined@ to execute a multi-worker protocol hosted on grid.js
    """
    static let swiftSyft = "SwiftSyft"
    static let swiftSyftKey = "@SwiftSyft@"
    static let swiftSyftURL = "https://github.com/OpenMined/SwiftSyft"
    static let openMined = "OpenMined"
    static let openMinedKey = "@OpenMined@"
    static let openMinedURL = "https://github.com/OpenMined/grid.js"
    static let socketURL = "ws://127.0.0.1:3000" // "wss://localhost:3000/"
    static let protocolID = "50801316202"
    static let connectButtonText = "Connect to grid.js server"
    static let disconnectButtonText = "Disconnect grid.js server"
    static let messagePlaceholder = "Enter your message ..."
    static let sendButtonText = "Send message"
}

class HomeViewController: UIViewController, UITextViewDelegate {
    var socket: SocketClientProtocol!
    var syftRTCClient: SyftRTCClient!
    var isConnected = false

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerDescriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var socketURLTextField: UITextField!
    @IBOutlet weak var protocolIDTextField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        headerDescriptionLabel.text = StaticHomeScreenStrings.headerDescription

        descriptionTextView.text = StaticHomeScreenStrings.description
        descriptionTextView.attributedText = descriptionTextView.attributedText?
            .fillInLink(StaticHomeScreenStrings.swiftSyftKey,
                        with: StaticHomeScreenStrings.swiftSyft,
                        url: StaticHomeScreenStrings.swiftSyftURL)
            .fillInLink(StaticHomeScreenStrings.openMinedKey,
                        with: StaticHomeScreenStrings.openMined,
                        url: StaticHomeScreenStrings.openMinedURL)

        socketURLTextField.text = StaticHomeScreenStrings.socketURL
        protocolIDTextField.text = StaticHomeScreenStrings.protocolID

        messageTextView.text = StaticHomeScreenStrings.messagePlaceholder
        messageTextView.textColor = UIColor.lightGray
        messageTextView.delegate = self
        sendButton.titleLabel?.text = StaticHomeScreenStrings.sendButtonText

        showServerConnectedUI(isConnected)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
      socket.disconnect()
      socket.delegate = nil
    }

    @IBAction func connectPressed(_ sender: UIButton) {

        // Connect using socket connection
//        if isConnected {
//            socket.disconnect()
//        } else {
//            guard !socketURLTextField.text!.isEmpty else {
//                print("Socket URL is empty!")
//                return
//            }
//            guard !protocolIDTextField.text!.isEmpty else {
//                print("Protocol ID is empty!")
//                return
//            }
//
//            var request = URLRequest(url: URL(string: StaticHomeScreenStrings.socketURL)!)
//            request.timeoutInterval = 5
//
//            socket = SyftWebSocket(url: request.url!,
//                                       pingInterval: request.timeoutInterval)
//            socket.delegate = self
//            socket.connect()
//        }

        // Connect using webrtc connection
        let socketURL = URL(string: StaticHomeScreenStrings.socketURL)!
        self.syftRTCClient = SyftRTCClient(socketURL: socketURL, workerId: UUID(uuidString: "eeb370bc-6a17-4cb3-9644-bde71e1a38a5")!, scopeId: UUID(uuidString: "d54cb968-517a-45b5-891d-4d233bbfa536")!)
        self.syftRTCClient.connect()

    }

    @IBAction func sendPressed(_ sender: Any) {
        guard !messageTextView.text!.isEmpty else {
            print("Message is empty!")
            return
        }
        socket.sendText(text: messageTextView.text)
        messageTextView.text = StaticHomeScreenStrings.messagePlaceholder
        messageTextView.textColor = UIColor.lightGray
    }

    func showServerConnectedUI(_ isConnected: Bool) {
        let hideUIElements = !isConnected
        messageTextView.isHidden = hideUIElements
        sendButton.isHidden = hideUIElements
        connectButton.titleLabel?.text = isConnected ?
            StaticHomeScreenStrings.disconnectButtonText :
            StaticHomeScreenStrings.connectButtonText
    }

    // MARK: - TextView behavior
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = StaticHomeScreenStrings.messagePlaceholder
            textView.textColor = UIColor.lightGray
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            messageTextView.contentInset = .zero
        } else {
            let userInfo = notification.userInfo!
            var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey]
                as? NSValue)!.cgRectValue
            keyboardFrame = self.view.convert(keyboardFrame, from: nil)

            var contentInset: UIEdgeInsets = self.scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            scrollView.contentInset = UIEdgeInsets(top: 0,
                                                   left: 0,
                                                   bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom,
                                                   right: 0)
        }

        messageTextView.scrollIndicatorInsets = messageTextView.contentInset

        let selectedRange = messageTextView.selectedRange
        messageTextView.scrollRangeToVisible(selectedRange)
    }
}

extension NSAttributedString {
    func fillInLink(_ placeholder: String, with link: String, url: String) -> NSAttributedString {
        let mutableAttr = NSMutableAttributedString(attributedString: self)
        let linkAttr = NSAttributedString(string: link, attributes: [NSAttributedString.Key.link: URL(string: url)!])
        let placeholderRange = (self.string as NSString).range(of: placeholder)

        mutableAttr.replaceCharacters(in: placeholderRange, with: linkAttr)
        return mutableAttr
    }
}

// MARK: - SocketClientDelegate
extension HomeViewController: SocketClientDelegate {
    func didConnect(_ socketClient: SocketClientProtocol) {
        isConnected = true
        showServerConnectedUI(isConnected)
    }

    func didDisconnect(_ socketClient: SocketClientProtocol) {
        isConnected = false
        showServerConnectedUI(isConnected)
    }

    func didReceive(socketMessage result: Result<Data, Error>) {
        //
    }
}
