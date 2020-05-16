//
//  HomeViewController.swift
//  SwiftSyft
//
//  Created by SashaBataieva on 01/20/2020.
//  Copyright (c) 2020 mjjimenez. All rights reserved.
//

import UIKit
import SwiftSyft
import Combine

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
    static let openMinedURL = "https://github.com/OpenMined/PyGrid/"
    static let socketURL = "ws://127.0.0.1:3000" // "wss://localhost:3000/"
    static let connectButtonText = "Connect to PyGrid server"
}

class HomeViewController: UIViewController, UITextViewDelegate {
    var isConnected = false

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerDescriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var socketURLTextField: UITextField!
    @IBOutlet weak var connectButton: UIButton!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!

    private var syftJob: SyftJob?
    private var syftClient: SyftClient?
    private var lossSubject: PassthroughSubject<Float, Error>?

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectPressed(_ sender: UIButton) {

        // Initate federated cycle request
        if let syftClient = SyftClient(url: URL(string: "ws://127.0.0.1:5000")!) {

            // Show loading UI
            self.connectButton.isHidden = true
            self.loadingLabel.isHidden = false
            self.activityIndicator.startAnimating()

            self.syftJob = syftClient.newJob(modelName: "mnist", version: "1.0.0")
            self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in

                DispatchQueue.main.sync {
                    self.loadingLabel.text = "Loading MNIST Data"
                }

                do {

                    let (mnistData, labels) = try MNISTLoader.load(setType: .train, batchSize: clientConfig.batchSize)

                    DispatchQueue.main.sync {

                        self.loadingLabel.isHidden = true
                        self.activityIndicator.stopAnimating()

                        // swiftlint:disable force_cast
                        let lineChartViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "LineChart") as! LossChartViewController
                        // swiftlint:enable force_cast

                        self.show(lineChartViewController, sender: self)

                        self.lossSubject = lineChartViewController.lossSubject

                    }

                    for case let (batchData, labels) in zip(mnistData, labels) {

                        try autoreleasepool {

                            let flattenedBatch = MNISTLoader.flattenMNISTData(batchData)
                            let oneHotLabels = MNISTLoader.oneHotMNISTLabels(labels: labels).compactMap { Float($0)}

                            let trainingData = try TrainingData(data: flattenedBatch, shape: [clientConfig.batchSize, 784])
                            let validationData = try ValidationData(data: oneHotLabels, shape: [clientConfig.batchSize, 10])

                            let loss = plan.execute(trainingData: trainingData, validationData: validationData, clientConfig: clientConfig)
                            self.lossSubject?.send(loss)
                            print("loss: \(loss)")

                        }

                    }

                    let diffStateData = try plan.generateDiffData()
                    modelReport(diffStateData)

                    self.lossSubject?.send(completion: .finished)

                } catch let error {
                    debugPrint(error.localizedDescription)
                }

            })
            self.syftJob?.onError(execute: { error in
                print(error)
            })
            self.syftJob?.start()
            self.syftClient = syftClient
        }
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.scrollView.contentInset = .zero
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
