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

enum HomeScreenStrings {
    static let headerDescription = "SwiftSyft Testing"
    static let description = """
        This is a demonstration of how to use @SwiftSyft@ with @PyGrid@ to train a plan on local data on an iOS device.
    """
    static let swiftSyft = "SwiftSyft"
    static let swiftSyftKey = "@SwiftSyft@"
    static let swiftSyftURL = "https://github.com/OpenMined/SwiftSyft"
    static let pygrid = "PyGrid"
    static let pygridKey = "@PyGrid@"
    static let pygridURL = "https://github.com/OpenMined/PyGrid/"
    static let socketURL = "ws://127.0.0.1:5000" // "wss://localhost:5000/"
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

        headerDescriptionLabel.text = HomeScreenStrings.headerDescription

        descriptionTextView.text = HomeScreenStrings.description
        descriptionTextView.attributedText = descriptionTextView.attributedText?
            .fillInLink(HomeScreenStrings.swiftSyftKey,
                        with: HomeScreenStrings.swiftSyft,
                        url: HomeScreenStrings.swiftSyftURL)
            .fillInLink(HomeScreenStrings.pygridKey,
                        with: HomeScreenStrings.pygrid,
                        url: HomeScreenStrings.pygridURL)

        socketURLTextField.text = HomeScreenStrings.socketURL
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectPressed(_ sender: UIButton) {

        // This is a demonstration of how to use SwiftSyft with PyGrid to train a plan on local data on an iOS device

        // Get token from here on the "Create Plan" notebook: https://github.com/OpenMined/PySyft/tree/master/examples/tutorials/model-centric-fl
        // swiftlint:disable:next line_length
        let authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.e30.Cn_0cSjCw1QKtcYDx_mYN_q9jO2KkpcUoiVbILmKVB4LUCQvZ7YeuyQ51r9h3562KQoSas_ehbjpz2dw1Dk24hQEoN6ObGxfJDOlemF5flvLO_sqAHJDGGE24JRE4lIAXRK6aGyy4f4kmlICL6wG8sGSpSrkZlrFLOVRJckTptgaiOTIm5Udfmi45NljPBQKVpqXFSmmb3dRy_e8g3l5eBVFLgrBhKPQ1VbNfRK712KlQWs7jJ31fGpW2NxMloO1qcd6rux48quivzQBCvyK8PV5Sqrfw_OMOoNLcSvzePDcZXa2nPHSu3qQIikUdZIeCnkJX-w0t8uEFG3DfH1fVA"

        // Create a client with a PyGrid server URL
        if let syftClient = SyftClient(url: URL(string: "ws://127.0.0.1:5000")!, authToken: authToken) {

            // Store the client as a property so it doesn't get deallocated during training.
            self.syftClient = syftClient

            // Show loading UI
            self.connectButton.isHidden = true
            self.loadingLabel.isHidden = false
            self.activityIndicator.startAnimating()

            // Create a new federated learning job with the model name and version
            self.syftJob = syftClient.newJob(modelName: "mnist", version: "1.0")

            // This function is called when SwiftSyft has downloaded the plans and model parameters from PyGrid
            // You are ready to train your model on your data
            // plan - Use this to generate diffs using our training data
            // clientConfig - contains the configuration for the training cycle (batchSize, learning rate) and metadata for the model (name, version)
            // modelReport - Used as a completion block and reports the diffs to PyGrid.
            self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in

                // Set label to show that MNIST data is currently being loaded into memory
                DispatchQueue.main.sync {
                    self.loadingLabel.text = "Loading MNIST Data"
                }

                do {

                    // This returns a lazily evaluated sequence for each MNIST image and the corresponding label
                    // It divides the training data and the label by batches
                    let (mnistData, labels) = try MNISTLoader.load(setType: .train, batchSize: clientConfig.batchSize)

                    // Stop the loading indicator and present the line chart view controller
                    // plotting the loss from training
                    DispatchQueue.main.sync {

                        self.loadingLabel.isHidden = true
                        self.activityIndicator.stopAnimating()

                        // swiftlint:disable force_cast
                        let lineChartViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "LineChart") as! LossChartViewController
                        // swiftlint:enable force_cast

                        self.show(lineChartViewController, sender: self)

                        self.lossSubject = lineChartViewController.lossSubject

                    }

                    // Iterate through each batch of MNIST data and label
                    for case let (batchData, labels) in zip(mnistData, labels) {

                        // We need to create an autorelease pool to release the training data from memory after each loop
                        try autoreleasepool {

                            // Preprocess MNIST data by flattening all of the MNIST batch data as a single array
                            let flattenedBatch = MNISTLoader.flattenMNISTData(batchData)

                            // Preprocess the label ( 0 to 9 ) by creating one-hot features and then flattening the entire thing
                            let oneHotLabels = MNISTLoader.oneHotMNISTLabels(labels: labels).compactMap { Float($0)}

                            // Since we don't have native tensor wrappers in Swift yet, we use `TrainingData` and `ValidationData`
                            // classes to store the data and shape.
                            let trainingData = try TrainingData(data: flattenedBatch, shape: [clientConfig.batchSize, 784])
                            let validationData = try ValidationData(data: oneHotLabels, shape: [clientConfig.batchSize, 10])

                            // Execute the plan with the training data and validation data. `plan.execute()` returns the loss and you can use
                            // it if you want to (plan.execute() has the @discardableResult attribute)
                            let loss = plan.execute(trainingData: trainingData, validationData: validationData, clientConfig: clientConfig)

                            // Pass the loss to the line chart view controller to plot.
                            self.lossSubject?.send(loss)
                            print("loss: \(loss)")

                        }

                    }

                    // Generate diff data and report the final diffs as
                    let diffStateData = try plan.generateDiffData()
                    modelReport(diffStateData)

                    self.lossSubject?.send(completion: .finished)

                } catch let error {

                    // Handle any error from the training cycle
                    debugPrint(error.localizedDescription)

                }

            })

            // This is the error handler for any job exeuction errors like connecting to PyGrid
            self.syftJob?.onError(execute: { error in
                print(error)
            })

            // This is the error handler for being rejected in a cycle. You can retry again
            // after the suggested timeout.
            self.syftJob?.onRejected(execute: { timeout in
                if let timeout = timeout {
                    // Retry again after timeout
                    print(timeout)
                }
            })

            // Start the job. You can set that the job should only execute if the device is being charge and there is a WiFi connection.
            // These options are true by default if you don't specify them.
            self.syftJob?.start(chargeDetection: false, wifiDetection: false)
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
