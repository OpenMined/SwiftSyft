//
//  LazyDataLoader.swift
//  OpenMinedSwiftSyft
//
//  Created by Rohith Pudari on 08/11/20.
//

import Foundation

//TODO: update with protocols

//protocol LazyDataLoaderProtocol: Sequence{
//
//    associatedtype dataset: Sequence
//
//    var dataset: dataset { get set }
//
//    init(dataset: dataset)
//}

struct LazyRandomIterator<T: Sequence> {

    var mutableSequence: [T.Element]
    var randomNumberGenerator: AnyRandomNumberGenerator

    init(sequence: T, randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.mutableSequence = Array(sequence)
        self.randomNumberGenerator = AnyRandomNumberGenerator(randomNumberGenerator)
    }

    mutating func next() -> T.Element? {

        guard let randomIndex = mutableSequence.indices.randomElement(using: &randomNumberGenerator) else {
            return nil
        }

        let randomElement = mutableSequence.remove(at: randomIndex)
        return randomElement
    }
}

class LazyDataLoader<T: Sequence>: Sequence {
    var dataset: T
    required init(dataset: T) {
        self.dataset = dataset
    }

    __consuming func makeIterator() -> AnyIterator<T.Element> {
        fatalError("Must subclass `LazyDataLoader`")
    }

}

class LazyTensorDataLoader<T: Sequence>: LazyDataLoader<T> where T.Element == TorchTensor {

    var iterator: AnyIterator<T.Element>

    init(dataset: T, batchSize: Int = 1) {

        guard batchSize >= 1 else {
            preconditionFailure("Batch size must be greater than or equal to 1")
        }

        self.iterator = AnyIterator(dataset.makeIterator())

        //      no shuffle in sequence


        if batchSize > 1 {
            self.iterator = AnyIterator(TensorBatchIterator(iterator: self.iterator, batchSize: batchSize))
        }

        super.init(dataset: dataset)

    }
    
    required init(dataset: T) {
        fatalError("init(dataset:) has not been implemented")
    }
    
    __consuming override func makeIterator() -> AnyIterator<T.Element> {
        return self.iterator
    }
}

class LazyMultiTensorDataLoader<T: Sequence>: LazyDataLoader<T> where T.Element == [TorchTensor] {

    var iterator: AnyIterator<T.Element>

    init(dataset: T, batchSize: Int = 1) {

        guard batchSize >= 1 else {
            preconditionFailure("Batch size must be greater than or equal to 1")
        }

        self.iterator = AnyIterator(dataset.makeIterator())
        
        // no shuffle in sequence

        if batchSize > 1 {
            self.iterator = AnyIterator(MultiTensorBatchIterator(iterator: self.iterator, batchSize: batchSize))
        }

        super.init(dataset: dataset)

    }
    
    required init(dataset: T) {
        fatalError("init(dataset:) has not been implemented")
    }
    
    __consuming override func makeIterator() -> AnyIterator<T.Element> {
        return self.iterator
    }

}
