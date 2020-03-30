//
//  MNISTLoader2.swift
//  Torch-Proto-Practice
//
//  MNISTLoader - Shao-Ping Lee on 3/26/16.
//  Reference From: https://github.com/simonlee2/MNISTKit
//  - Modified to add split loading of training and test data
//  - Added batching of data and labels

import Foundation

// Load either train/test data
// Batch data according to batch size

enum ImageSetType {
    case train
    case test
}

enum MNISTError: Error {
    case fileError
}

private enum DataFileType {
    case image
    case label
}

class MNISTLoader {

    static func load(setType: ImageSetType, batchSize: Int) throws -> (data: LazyChunkSequence<[[Float]]>, labels: LazyChunkSequence<[Int]>) {

        switch setType {
        case .train:
            let (trainData, trainLabel) = try loadTrain()
            return (trainData.lazyChunkSequence(size: batchSize), trainLabel.lazyChunkSequence(size: batchSize))
        case .test:
            let (testData, testLabel) = try loadTest()
            return (testData.lazyChunkSequence(size: batchSize), testLabel.lazyChunkSequence(size: batchSize))
        }

    }

    static func oneHotMNISTLabels(labels: [Int]) -> [Int] {

        var oneHotArray: [Int] = [Int]()
        for label in labels {
            var oneHotColumn = [Int](repeating: 0, count: 10)
            oneHotColumn[label] = 1
            oneHotArray.append(contentsOf: oneHotColumn)
        }

        return oneHotArray
    }

    static func flattenMNISTData(_ mnistArray: [[Float]]) -> [Float] {

        let result = mnistArray.flatMap { $0 }
        return result

    }

    private static func loadTrain() throws -> ([[Float]], [Int]) {

        let mainBundle = Bundle.main
        guard
            let trainImagesURL = mainBundle.url(forResource: "train-images-idx3-ubyte", withExtension: nil),
            let trainImageData = NSData(contentsOf: trainImagesURL),
            let trainLabelsURL = mainBundle.url(forResource: "train-labels-idx1-ubyte", withExtension: nil),
            let trainLabelData = NSData(contentsOf: trainLabelsURL),
            let trainImages = imageData(data: trainImageData),
            let trainLabels = labelData(data: trainLabelData) else {
                throw MNISTError.fileError
        }

        return (trainImages, trainLabels)

    }

    private static func loadTest() throws -> ([[Float]], [Int]) {

        let mainBundle = Bundle.main
        guard
            let testImagesURL = mainBundle.url(forResource: "t10k-images-idx3-ubyte", withExtension: nil),
            let testImageData = NSData(contentsOf: testImagesURL),
            let testLabelsURL = mainBundle.url(forResource: "t10k-labels-idx1-ubyte", withExtension: nil),
            let testLabelData = NSData(contentsOf: testLabelsURL),
            let testImages = imageData(data: testImageData),
            let testLabels = labelData(data: testLabelData) else {
                throw MNISTError.fileError
        }

        return (testImages, testLabels)
    }

    private static func labelData(data: NSData) -> [Int]? {
        let (_, nItem) = readLabelFileHeader(data: data)

        let range = 0..<Int(nItem)
        let extractLabelClosure: (Int) -> UInt8 = { itemIndex in
            return self.extractLabel(data: data, labelIndex: itemIndex)
        }

        return range.map(extractLabelClosure).map(Int.init)
    }

    private static func imageData(data: NSData) -> [[Float]]? {
        guard let (_, nItem, nCol, nRow) = readImageFileHeader(data: data) else { return nil }

        let imageLength = Int(nCol * nRow)
        let range = 0..<Int(nItem)
        let extractImageClosure: (Int) -> [Float] = { itemIndex in
            return self.extractImage(data: data, pixelCount: imageLength, imageIndex: itemIndex)
                .map({Float($0)/255})
        }

        return range.map(extractImageClosure)
    }

    private static func extractImage(data: NSData, pixelCount: Int, imageIndex: Int) -> [UInt8] {
        var byteArray = [UInt8](repeating: 0, count: pixelCount)
        data.getBytes(&byteArray, range: NSRange(location: 16 + imageIndex * pixelCount, length: pixelCount))
        return byteArray
    }

    private static func extractLabel(data: NSData, labelIndex: Int) -> UInt8 {
        var byte: UInt8 = 0
        data.getBytes(&byte, range: NSRange(location: 8 + labelIndex, length: 1))
        return byte
    }
//  swiftlint:disable large_tuple
    private static func readImageFileHeader(data: NSData) -> (UInt32, UInt32, UInt32, UInt32)? {
        let header = readHeader(data: data, dataType: .image)
        guard let col = header.2, let row = header.3 else { return nil }
        return (header.0, header.1, col, row)
    }

    private static func readLabelFileHeader(data: NSData) -> (UInt32, UInt32) {
        let header = readHeader(data: data, dataType: .label)
        return (header.0, header.1)
    }

    private static func readHeader(data: NSData, dataType: DataFileType) -> (UInt32, UInt32, UInt32?, UInt32?) {
        switch dataType {
        case .image:
            let headerValues = data.bigEndianInt32s(range: (0..<4))
            return (headerValues[0], headerValues[1], headerValues[2], headerValues[3])
        case .label:
            let headerValues = data.bigEndianInt32s(range: (0..<2))
            return (headerValues[0], headerValues[1], nil, nil)
        }
    }
// swiftlint:enable large_tuple

}

extension NSData {
    func bigEndianInt32(location: Int) -> UInt32? {
        var value: UInt32 = 0
        self.getBytes(&value, range: NSRange(location: location, length: MemoryLayout<UInt32>.size))
        return UInt32(bigEndian: value)
    }

    func bigEndianInt32s(range: Range<Int>) -> [UInt32] {
        return range.compactMap({bigEndianInt32(location: $0 * MemoryLayout<UInt32>.size)})
    }
}

// Lazy chunked array
// https://forums.swift.org/t/chunking-collections-and-strings-in-swift-5-1/26524/8

public struct LazyChunkSequence<T: Collection>: Sequence, IteratorProtocol {

    private var baseIterator: T.Iterator
    private let size: Int

    fileprivate init(over collection: T, chunkSize size: Int) {
        baseIterator = collection.lazy.makeIterator()
        self.size = size
    }

    mutating public func next() -> [T.Element]? {
        var chunk: [T.Element] = []

        var remaining = size
        while remaining > 0, let nextElement = baseIterator.next() {
            chunk.append(nextElement)
            remaining -= 1
        }

        if chunk.count < size {
            return nil
        }

        return chunk.isEmpty ? nil : chunk
    }

}

extension Collection {

    public func lazyChunkSequence(size: Int) -> LazyChunkSequence<Self> {
        return LazyChunkSequence(over: self, chunkSize: size)
    }

}
