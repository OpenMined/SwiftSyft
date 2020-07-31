//
//  AppDelegate.swift
//  SwiftSyft-Background
//
//  Created by Mark Jeremiah Jimenez on 08/05/2020.
//  Copyright © 2020 OpenMined. All rights reserved.
//

import UIKit
import SwiftSyft
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var syftJob: SyftJob?
    private var syftClient: SyftClient?

    // Flag that we check if the background task  has been cancelled.
    private var backgroundTaskCancelled = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.openmined.background", using: DispatchQueue.global()) { task in

            self.executeSyftJob(backgroundTask: task)

        }

        self.scheduleTrainingJob()

        return true
    }

    func scheduleTrainingJob() {
        do {
            let processingTaskRequest = BGProcessingTaskRequest(identifier: "com.openmined.background")
            processingTaskRequest.requiresExternalPower = true
            processingTaskRequest.requiresNetworkConnectivity = true
            try BGTaskScheduler.shared.submit(processingTaskRequest)

        } catch {
            print(error.localizedDescription)
        }
    }

    func executeSyftJob(backgroundTask: BGTask) {

        // This is a demonstration of how to use SwiftSyft with PyGrid to train a plan on local data on an iOS device

        // Get token from here on the "Create Plan" notebook: https://github.com/OpenMined/PySyft/tree/master/examples/tutorials/model-centric-fl
        // swiftlint:disable:next line_length
        let authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.e30.Cn_0cSjCw1QKtcYDx_mYN_q9jO2KkpcUoiVbILmKVB4LUCQvZ7YeuyQ51r9h3562KQoSas_ehbjpz2dw1Dk24hQEoN6ObGxfJDOlemF5flvLO_sqAHJDGGE24JRE4lIAXRK6aGyy4f4kmlICL6wG8sGSpSrkZlrFLOVRJckTptgaiOTIm5Udfmi45NljPBQKVpqXFSmmb3dRy_e8g3l5eBVFLgrBhKPQ1VbNfRK712KlQWs7jJ31fGpW2NxMloO1qcd6rux48quivzQBCvyK8PV5Sqrfw_OMOoNLcSvzePDcZXa2nPHSu3qQIikUdZIeCnkJX-w0t8uEFG3DfH1fVA"

        // Create a client with a PyGrid server URL
        guard let syftClient = SyftClient(url: URL(string: "ws://127.0.0.1:5000")!, authToken: authToken) else {

            // Set background task failed if creating a client fails
            backgroundTask.setTaskCompleted(success: false)
            return
        }

        // Store the client as a property so it doesn't get deallocated during training.
        self.syftClient = syftClient

        // Create a new federated learning job with the model name and version
        self.syftJob = syftClient.newJob(modelName: "mnist", version: "1.0.0")

        // This function is called when SwiftSyft has downloaded the plans and model parameters from PyGrid
        // You are ready to train your model on your data
        // plan - Use this to generate diffs using our training data
        // clientConfig - contains the configuration for the training cycle (batchSize, learning rate) and metadata for the model (name, version)
        // modelReport - Used as a completion block and reports the diffs to PyGrid.
        self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in

            do {

                // This returns a lazily evaluated sequence for each MNIST image and the corresponding label
                // It divides the training data and the label by batches
                let (mnistData, labels) = try MNISTLoader.load(setType: .train, batchSize: clientConfig.batchSize)

                // Iterate through each batch of MNIST data and label
                for case let (batchData, labels) in zip(mnistData, labels) {

                    // This checks if the background task has been cancelled. If it is, cancel the training cycle
                    guard !self.backgroundTaskCancelled else {
                        return
                    }

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
                        plan.execute(trainingData: trainingData, validationData: validationData, clientConfig: clientConfig)

                    }

                }

                // Generate diff data and report the final diffs as
                let diffStateData = try plan.generateDiffData()
                modelReport(diffStateData)

                // Finish the background task
                backgroundTask.setTaskCompleted(success: true)

            } catch let error {

                // Handle any error from the training cycle
                debugPrint(error.localizedDescription)

                // Set the background task as failed after an error
                backgroundTask.setTaskCompleted(success: false)
            }

        })

        // This is the error handler for any job exeuction errors like connecting to PyGrid
        self.syftJob?.onError(execute: { error in
            print(error.localizedDescription)
            backgroundTask.setTaskCompleted(success: false)
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
        self.syftJob?.start()

        // If the background task has expired,
        // we set this flag as true so that the training cycle
        // can be informed and cancel any following cycles
        backgroundTask.expirationHandler = {
            self.backgroundTaskCancelled = true
        }
    }


}

