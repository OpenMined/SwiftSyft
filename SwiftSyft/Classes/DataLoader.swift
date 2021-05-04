import Foundation

protocol TorchIValueConvertable {
    func convertToIValue() -> [TorchIValue]
}

extension Array: TorchIValueConvertable where Element == TorchTensor {

    func convertToIValue() -> [TorchIValue] {
        self.map { TorchIValue.new(with: $0) }
    }

}

extension TorchTensor: TorchIValueConvertable {

    func convertToIValue() -> [TorchIValue] {
        return [TorchIValue.new(with: self)]
    }

}

// Swift for tensorflow wrapper for RandomNumberGenerator
struct AnyRandomNumberGenerator: RandomNumberGenerator {
    var rng: RandomNumberGenerator

    init(_ rng: RandomNumberGenerator) {
        self.rng = rng
    }

    mutating func next() -> UInt64 {
        return self.rng.next()
    }
}

struct RandomIterator<T: Collection>: IteratorProtocol {

    var mutableCollection: [T.Element]
    var randomNumberGenerator: AnyRandomNumberGenerator

    init(collection: T, randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.mutableCollection = Array(collection)
        self.randomNumberGenerator = AnyRandomNumberGenerator(randomNumberGenerator)
    }

    mutating func next() -> T.Element? {

        guard let randomIndex = mutableCollection.indices.randomElement(using: &randomNumberGenerator) else {
            return nil
        }

        let randomElement = mutableCollection.remove(at: randomIndex)
        return randomElement
    }
}

struct TensorBatchIterator<T: IteratorProtocol>: IteratorProtocol where T.Element == TorchTensor {

    var iterator: T
    let batchSize: Int

    init(iterator: T, batchSize: Int) {
        self.iterator = iterator
        self.batchSize = batchSize
    }

    mutating func next() -> T.Element? {

        var resultArray: [T.Element] = []

        for _ in 1...batchSize {

            if let next = iterator.next() {
                resultArray.append(next)
            } else {
                return nil
            }

        }

        guard resultArray.count == batchSize else {
            return nil
        }

        let resultTensor = TorchTensor.cat(resultArray)

        return resultTensor

    }
}

struct MultiTensorBatchIterator<T: IteratorProtocol>: IteratorProtocol where T.Element == [TorchTensor] {

    var iterator: T
    var batchSize: Int

    init(iterator: T, batchSize: Int) {
        self.iterator = iterator
        self.batchSize = batchSize
    }

    mutating func next() -> T.Element? {
        var result: [T.Element] = []

        for _ in 1...batchSize {

            if let next = iterator.next() {
                result.append(next)
            } else {
                return nil
            }

        }

        guard let first = result.first,
              result.allSatisfy({ $0.count == first.count }) else {
            return nil
        }

        // Initialize array tensors to stack
        var tensorsToStack: [[TorchTensor]] = Array(repeating: [], count: first.count)

        // Zip then combine tensors per element
        for row in result {
            for index in 0..<row.count {
                tensorsToStack[index].append(row[index])
            }
        }

        return tensorsToStack.map { $0.stackTensors() }
    }

}

extension Array where Element == TorchTensor {

    func stackTensors() -> TorchTensor {
        return TorchTensor.cat(self)
    }
}

public class DataLoader<T: Collection>: Sequence {

    let dataset: T

    init(dataset: T) {
        self.dataset = dataset
    }

    public __consuming func makeIterator() -> AnyIterator<T.Element> {
        fatalError("Must subclass `DataLoader`")
    }

}

public class TensorDataLoader<T: Collection>: DataLoader<T> where T.Element == TorchTensor {

    var iterator: AnyIterator<T.Element>

    init(dataset: T, shuffle: Bool = true, batchSize: Int = 1) {

        guard batchSize >= 1 else {
            preconditionFailure("Batch size must be greater than or equal to 1")
        }

        self.iterator = AnyIterator(dataset.makeIterator())

        if shuffle {
            self.iterator = AnyIterator(RandomIterator(collection: dataset))
        }

        if batchSize > 1 {
            self.iterator = AnyIterator(TensorBatchIterator(iterator: self.iterator, batchSize: batchSize))
        }

        super.init(dataset: dataset)

    }

    public __consuming override func makeIterator() -> AnyIterator<T.Element> {
        return self.iterator
    }
}

public class MultiTensorDataLoader<T: Collection>: DataLoader<T> where T.Element == [TorchTensor] {

    var iterator: AnyIterator<T.Element>

    public init(dataset: T, shuffle: Bool = true, batchSize: Int = 1) {

        guard batchSize >= 1 else {
            preconditionFailure("Batch size must be greater than or equal to 1")
        }

        self.iterator = AnyIterator(dataset.makeIterator())

        if shuffle {
            self.iterator = AnyIterator(RandomIterator(collection: dataset))
        }

        if batchSize > 1 {
            self.iterator = AnyIterator(MultiTensorBatchIterator(iterator: self.iterator, batchSize: batchSize))
        }

        super.init(dataset: dataset)

    }

    public __consuming override func makeIterator() -> AnyIterator<T.Element> {
        return self.iterator
    }

}
