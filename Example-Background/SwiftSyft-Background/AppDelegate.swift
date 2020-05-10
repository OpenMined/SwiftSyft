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
    private var backgroundTaskCancelled = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "", using: DispatchQueue.global()) { task in

            self.executeSyftJob(backgroundTask: task)

        }

        return true
    }

    func executeSyftJob(backgroundTask: BGTask) {

        // Initate federated cycle request
        guard let syftClient = SyftClient(url: URL(string: "ws://127.0.0.1:5000")!) else {
            backgroundTask.setTaskCompleted(success: false)
            return
        }

        self.syftJob = syftClient.newJob(modelName: "mnist", version: "1.0.0")
        self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in

            do {

                let (mnistData, labels) = try MNISTLoader.load(setType: .train, batchSize: clientConfig.batchSize)

                for case let (batchData, labels) in zip(mnistData, labels) {

                    guard !self.backgroundTaskCancelled else {
                        return
                    }

                    let flattenedBatch = MNISTLoader.flattenMNISTData(batchData)
                    let oneHotLabels = MNISTLoader.oneHotMNISTLabels(labels: labels).compactMap { Float($0)}

                    let trainingData = try TrainingData(data: flattenedBatch, shape: [clientConfig.batchSize, 784])
                    let validationData = try ValidationData(data: oneHotLabels, shape: [clientConfig.batchSize, 10])

                    plan.execute(trainingData: trainingData, validationData: validationData, clientConfig: clientConfig)
                }

                let diffStateData = try plan.generateDiffData()
                modelReport(diffStateData)

                backgroundTask.setTaskCompleted(success: true)

            } catch let error {
                debugPrint(error.localizedDescription)
                backgroundTask.setTaskCompleted(success: false)
            }

        })
        self.syftJob?.onError(execute: { error in
            print(error.localizedDescription)
            backgroundTask.setTaskCompleted(success: false)
        })
        self.syftJob?.start()
        self.syftClient = syftClient
        backgroundTask.expirationHandler = {
            self.backgroundTaskCancelled = true
        }
    }


}

