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
        } receiveValue: { jobEvent in
            print(jobEvent)
        }.store(in: &self.disposeBag)
    }

    func onStarted(closure: @escaping () -> Void) {
        self.observations.started.append(closure)
    }

    func onEpochStart(closure: @escaping (Int) -> Void) {
        self.observations.epochStart.append(closure)
    }

    func onEpochEnd(closure: @escaping (Int) -> Void) {
        self.observations.epochStart.append(closure)
    }

    func onBatchStart(closure: @escaping (Int, Int) -> Void) {
        self.observations.batchStart.append(closure)
    }

    func onBatchEnd(closure: @escaping (Int, Int) -> Void) {
        self.observations.batchEnd.append(closure)
    }

    func onEnded(closure: @escaping () -> Void) {
        self.observations.ended.append(closure)
    }

    func onError(closure: @escaping (Error) -> Void) {
        self.observations.error.append(closure)
    }

}
