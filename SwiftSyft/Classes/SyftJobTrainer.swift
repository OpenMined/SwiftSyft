//
//  SyftJobTrainer.swift
//  OpenMinedSwiftSyft
//
//  Created by Mark Jeremiah Jimenez on 1/8/21.
//

import Foundation
import Combine

public enum SyftJobTrainerError: Error, LocalizedError {
    case inputSpecError(spec: PlanInputSpec)

    public var localizedDescription: String {
        switch self {
        case .inputSpecError(let spec):
            return "Invalid Input Spec \(spec)"
        }
    }
}

public enum PlanInputSpec {

    case data(dataIndex: Int)
    case clientConfig(keyPath: PartialKeyPath<FederatedClientConfig>)
    case modelParams
    case modelParam(paramIndex: Int)

}

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
    private var planName: String
    private var inputSpecs: [PlanInputSpec]

    var disposeBag = Set<AnyCancellable>()

    init(dataLoader: AnySequence<[TorchTensor]>,
         planName: String,
         inputSpecs: [PlanInputSpec],
         jobEventPublisher: AnyPublisher<SyftJobEvents, Error>) {

        self.dataLoader = dataLoader
        self.planName = planName
        self.inputSpecs = inputSpecs

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

                    guard let planParameters: [TorchIValue] = try? self.planParametersFrom(data: batch,
                                                                                           model: model,
                                                                                           planDictionary: planDictionary,
                                                                                           clientConfig: clientConfig) else {

                        // TODO: Add error handlers instead of return
                        return
                    }

                    let result = planDictionary[self.planName]?.forward(planParameters)

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

                    print("end autorelease")

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

    func planParametersFrom(data: [TorchTensor], model: SyftModel, planDictionary: [String: TorchModule], clientConfig: FederatedClientConfig) throws -> [TorchIValue] {

        var parameters: [TorchIValue] = []

        for spec in self.inputSpecs {

            switch spec {
            case .data(let index):
                parameters.append(TorchIValue.new(with: data[index]))
            case .clientConfig(let keyPath):
                guard let configTensor = clientConfig.tensorFromProperty(with: keyPath) else {
                    throw SyftJobTrainerError.inputSpecError(spec: spec)
                }

                parameters.append(TorchIValue.new(with: configTensor))

            case .modelParam(let paramIndex):

                guard let modelParams = model.paramTensorsForTraining else {
                    throw SyftJobTrainerError.inputSpecError(spec: spec)
                }

                parameters.append(TorchIValue.new(with: modelParams[paramIndex]))

            case .modelParams:

                guard let modelParams = model.paramTensorsForTraining else {
                    throw SyftJobTrainerError.inputSpecError(spec: spec)
                }

                parameters.append(TorchIValue.new(withTensorList: modelParams))

            }

        }

        return parameters
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
