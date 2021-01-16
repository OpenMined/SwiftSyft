//
//  SyftJobTrainer.swift
//  OpenMinedSwiftSyft
//
//  Created by Mark Jeremiah Jimenez on 1/8/21.
//

import Foundation
import Combine

public class SyftJobTrainer {
//public class SyftJobTrainer {

    private var observations = (
        started: [() -> Void](),
        ended: [() -> Void](),
        epochStart: [(Int) -> Void](),
        epochEnd: [(Int) -> Void](),
        batchStart: [(Int, Int) -> Void](),
        batchEnd: [(Int, Int) -> Void](),
        error: [(Error) -> Void]()
    )

    private var dataLoader: AnySequence<[TorchTensor]>

    var disposeBag = Set<AnyCancellable>()

    init(dataLoader: AnySequence<[TorchTensor]>,
         jobEventPublisher: AnyPublisher<SyftJobEvents, Error>) {

        self.dataLoader = dataLoader

        jobEventPublisher.sink { result in
            print(result)
        } receiveValue: { [unowned self] jobEvent in

            switch jobEvent {
            case .onReady(let model, planDictionary: let planDictionary, let clientConfig, let modelReport):

                self.startTraining(model: model, planDictionary: planDictionary, clientConfig: clientConfig, report: modelReport)

            case .onRejected(timeout: _):
                // TODO: Add error handlers
                print("job trainer rejected")
            case .onError(error: _):
                // TODO: Add error handlers
                print("job trainer error")
            }

        }.store(in: &self.disposeBag)
    }

    func startTraining(model: SyftModel, planDictionary: [String: TorchModule], clientConfig: FederatedClientConfig, report: ModelReport) {

        self.observations.started.forEach { closure in
            closure()
        }

        for epoch in 0..<clientConfig.maxEpochs {

            var batchIdx = 0

            self.observations.epochStart.forEach { closure in
                closure(epoch)
            }

            for batch in self.dataLoader {

                self.observations.batchStart.forEach { closure in
                    closure(epoch, batchIdx)
                }

                // We need to create an autorelease pool to release the training data from memory after each loop
                autoreleasepool {

                    // Preprocess MNIST data by flattening all of the MNIST batch data as a single array
                    let MNISTTensors = batch[0]

                    // Preprocess the label ( 0 to 9 ) by creating one-hot features and then flattening the entire thing
                    let labels = batch[1]

                    // Add batch_size, learning_rate and model_params as tensors
                    let batchSize = [clientConfig.batchSize]
                    let learningRate = [clientConfig.learningRate]

                    guard
                        let batchSizeTensor = TorchTensor.new(array: batchSize, size: [1]),
                        let learningRateTensor = TorchTensor.new(array: learningRate, size: [1]) ,
                        let modelParamTensors = model.paramTensorsForTraining else
                    {
                        return
                    }

                    // Execute the torchscript plan with the training data, validation data, batch size, learning rate and model params
                    let result = planDictionary["training_plan"]?.forward([TorchIValue.new(with: MNISTTensors),
                                                                  TorchIValue.new(with: labels),
                                                                  TorchIValue.new(with: batchSizeTensor),
                                                                  TorchIValue.new(with: learningRateTensor),
                                                                  TorchIValue.new(withTensorList: modelParamTensors)])

                    // Example returns a list of tensors in the folowing order: loss, accuracy, model param 1,
                    // model param 2, model param 3, model param 4
                    guard let tensorResults = result?.tupleToTensorList() else {
                        return
                    }

                    let lossTensor = tensorResults[0]
                    lossTensor.print()
                    let loss = lossTensor.item()

                    print("loss: \(loss)")

                    let accuracyTensor = tensorResults[1]
                    accuracyTensor.print()

                    // Get updated param tensors and update them in param tensors holder
                    let param1 = tensorResults[2]
                    let param2 = tensorResults[3]
                    let param3 = tensorResults[4]
                    let param4 = tensorResults[5]

                    model.paramTensorsForTraining = [param1, param2, param3, param4]

                }

                self.observations.batchEnd.forEach { closure in
                    closure(epoch, batchIdx)
                }

                batchIdx += 1
            }

            self.observations.epochEnd.forEach { closure in
                closure(epoch)
            }

        }

        self.observations.ended.forEach { closure in
            closure()
        }

    }

    public func onStarted(closure: @escaping () -> Void) {
        self.observations.started.append(closure)
    }

    public func onEpochStart(closure: @escaping (Int) -> Void) {
        self.observations.epochStart.append(closure)
    }

    public func onEpochEnd(closure: @escaping (Int) -> Void) {
        self.observations.epochEnd.append(closure)
    }

    public func onBatchStart(closure: @escaping (Int, Int) -> Void) {
        self.observations.batchStart.append(closure)
    }

    public func onBatchEnd(closure: @escaping (Int, Int) -> Void) {
        self.observations.batchEnd.append(closure)
    }

    public func onEnded(closure: @escaping () -> Void) {
        self.observations.ended.append(closure)
    }

    public func onError(closure: @escaping (Error) -> Void) {
        self.observations.error.append(closure)
    }

}
