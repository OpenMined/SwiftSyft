//
//  SyftJobTrainer.swift
//  OpenMinedSwiftSyft
//
//  Created by Mark Jeremiah Jimenez on 1/8/21.
//

import Foundation
import Combine

//public class SyftJobTrainer<T: Collection> where T.Element == [TorchTensor] {
public class SyftJobTrainer {

    private var observations = (
        started: [() -> Void](),
        ended: [() -> Void](),
        epochStart: [(Int) -> Void](),
        epochEnd: [(Int) -> Void](),
        batchStart: [(Int, Int) -> Void](),
        batchEnd: [(Int, Int) -> Void](),
        error: [(Error) -> Void]()
    )

//    private var dataloader: MultiTensorDataLoader<T>?

    var disposeBag = Set<AnyCancellable>()

    init(jobEventPublisher: AnyPublisher<SyftJobEvents, Error>) {
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

            for batch in 0...10 {

                self.observations.batchStart.forEach { closure in
                    closure(epoch, batch)
                }




                self.observations.batchEnd.forEach { closure in
                    closure(epoch, batch)
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
