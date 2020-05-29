
![CI](https://img.shields.io/github/workflow/status/openmined/swiftsyft/SwiftSyft CI)
![Licence](https://img.shields.io/github/license/openmined/swiftsyft)
![Contributors](https://img.shields.io/opencollective/all/openmined)

# SwiftSyft

SwiftSyft makes it easy for you to **train and inference PySyft models on iOS devices**. This allows you to utilize training data located directly on the device itself, bypassing the need to send a user's data to a central server. This is known as [federated learning](https://ai.googleblog.com/2017/04/federated-learning-collaborative.html).

- :gear: **Training and inference** of any PySyft model written in PyTorch or TensorFlow
- :bust_in_silhouette: Allows all data to stay on the user's device
- :back: Support for delegation to background task scheduler
- :key: Support for **JWT authentication** to protect models from Sybil attacks
- :+1: Host of **inbuilt best practices** to prevent apps from over using device resources. 
    - :electric_plug: **Charge detection** to allow background training only when device is connected to charger
    - :zzz: **Sleep and wake detection** so that the app does not occupy resource when user starts using the device
    - :money_with_wings: **Wifi and metered network detection** to ensure the model updates do not use all the available data quota 
    - :no_bell: All of these smart defaults are easily are **overridable**
- :mortar_board: Support for both reactive and callback patterns so you have your freedom of choice (_in progress_)
- :lock: Support for **secure multi-party computation** and **secure aggregation** protocols using **peer-to-peer WebRTC** connections (_in progress_).

There are a variety of additional privacy-preserving protections that may be applied, including [differential privacy](https://towardsdatascience.com/understanding-differential-privacy-85ce191e198a), [muliti-party computation](https://www.inpher.io/technology/what-is-secure-multiparty-computation), and [secure aggregation](https://research.google/pubs/pub45808/).

[OpenMined](https://openmined.org) set out to build the **world's first open-source ecosystem for federated learning on web and mobile**. SwiftSyft is a part of this ecosystem, responsible for bringing secure federated learning to iOS devices. You may also train models on Android devices using [KotlinSyft](https://github.com/OpenMined/KotlinSyft) or in web browsers using [syft.js](https://github.com/OpenMined/syft.js).

If you want to know how scalable federated systems are built, [Towards Federated Learning at Scale](https://arxiv.org/pdf/1902.01046.pdf) is a fantastic introduction!

## Installation
We have not currently made our initial release. SwiftSyft would soon be available on Cocoapods.

## Quick Start
As a developer, there are few steps to building your own secure federated learning system upon the OpenMined infrastructure:

1. :robot: Generate your secure ML model using [PySyft](https://github.com/OpenMined/PySyft). By design, PySyft is built upon PyTorch and TensorFlow so you **don't need to learn a new ML framework**. You will also need to write a training plan (training code the worker runs) and an averaging plan (code that PyGrid runs to average the model diff).
2. :earth_americas: Host your model and plans on [PyGrid](https://github.com/OpenMined/PyGrid) which will deal with all the federated learning components of your pipeline. You will need to set up a PyGrid server somewhere, please see their installation instructions on how to do this.
3. :tada: Start training on the device!

**:notebook: The entire workflow and process is described in greater detail in our [project roadmap](https://github.com/OpenMined/Roadmap/blob/master/web_and_mobile_team/projects/federated_learning.md).**

You can use SwiftSyft as a front-end or as a background service. The following is a quick start example usage:

```swift
        // Create a client with a PyGrid server URL
        if let syftClient = SyftClient(url: URL(string: "ws://127.0.0.1:5000")!) {

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

                        }

                    }

                    // Generate diff data and report the final diffs as 
                    let diffStateData = try plan.generateDiffData()
                    modelReport(diffStateData)

                } catch let error {
                    // Handle any error from the training cycle
                    debugPrint(error.localizedDescription)
                }

            })

            // This is the error handler for any job exeuction errors like connecting to PyGrid 
            self.syftJob?.onError(execute: { error in
                print(error)
            })

            // Start the job. You can set that the job should only execute if the device is being charge and there is a WiFi connection.
            // These options are on by default if you don't specify them.
            self.syftJob?.start(chargeDetection: true, wifiDetection: true)
            self.syftClient = syftClient
        }
```

## Development

SwiftSyft's library structure was made using `pod lib create`. If you're not familiar with it, you can check out https://guides.cocoapods.org/making/using-pod-lib-create.

## Set-up

You can work on the project by running `pod install` in the root directory. Then open the file `SwiftSyft.xcworkspace` in Xcode. When the project is open on Xcode, you can work on the `SwiftSyft` pod itself in `Pods/Development Pods/SwiftSyft/Classes/*`

The example works by first downloading a training plan from a PyGrid server, running that plan on MNIST data then uploading the model parameter diffs back up to PyGrid.

## PyGrid Setup

Easiest way to get a PyGrid server running on your local computer is to clone the PyGrid Repo then run `docker-compose`

1. `git clone https://github.com/OpenMined/PyGrid.git`
2. `cd` to the PyGrid directory and enter `docker-compose up` on your shell.
3. The `grid-gateway` container will be what we're using and should be running on `127.0.0.1:5000`

If you're having any trouble, try updating `grid-gateway` in `docker-compose.yml` to use `:dev` tag since that tag would hold the latest builds of PyGrid.

## Plan Hosting

The training plan can be created using the notebooks here: https://github.com/OpenMined/PySyft/tree/master/examples/experimental/FL%20Training%20Plan particularly the `Create Plan` and `Host Plan` notebooks.

You are going to need to install PySyft on your Python environment to run them so follow the instructions here: https://github.com/OpenMined/PySyft/blob/dev/INSTALLATION.md

`SwiftSyft` currently supports version `0.2.5` of PySyft.

## Example App

The example app should work by default and is configured to use localhost to query hosted plans.

## License

SwiftSyft is available under the Apache 2 license. See the LICENSE file for more info.
