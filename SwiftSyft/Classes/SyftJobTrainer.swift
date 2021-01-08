//
//  SyftJobTrainer.swift
//  OpenMinedSwiftSyft
//
//  Created by Mark Jeremiah Jimenez on 1/8/21.
//

import Foundation

enum JobTrainerEvents {
    case start
    case end
    case epochStart
    case epochEnd
    case batchStart
    case batchEnd
    case error
}

class SyftJobTrainer<T: Collection> where T.Element == [TorchTensor] {

    private var observations = (
        started: [() -> Void](),
        ended: [() -> Void](),
        epochStart: [(Int) -> Void](),
        epochEnd: [(Int) -> Void](),
        batchStart: [() -> Void](),
        batchEnd: [() -> Void](),
        error: [(Error) -> Void]()
    )

    private var dataloader: MultiTensorDataLoader<T>

    init(dataloader: MultiTensorDataLoader<T>) {
        self.dataloader = dataloader
    }

}
