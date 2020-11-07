//
//  LazyDataLoaderTests.swift
//  OpenMinedSwiftSyft-Unit-Tests
//
//  Created by Rohith Pudari on 08/11/20.
//

import XCTest
import GameplayKit
@testable import SwiftSyft

// https://stackoverflow.com/questions/54821659/swift-4-2-seeding-a-random-number-generator
struct SeededGenerator : RandomNumberGenerator {

    mutating func next() -> UInt64 {
        // GKRandom produces values in [INT32_MIN, INT32_MAX] range; hence we need two numbers to produce 64-bit value.
        let next1 = UInt64(bitPattern: Int64(gkrandom.nextInt()))
        let next2 = UInt64(bitPattern: Int64(gkrandom.nextInt()))
        return next1 ^ (next2 << 32)
    }

    init(seed: UInt64) {
        self.gkrandom = GKMersenneTwisterRandomSource(seed: seed)
    }

    private let gkrandom: GKRandom
}

// LibTorch tensor operations (ex. torch::cat) currently not working in
// test target with error message: "PyTorch is not linked with support for cpu devices".
// Will wait for these operations to work before adding more tests.
class DataLoaderTests: XCTestCase {

    func testRandomIterator() {

        let original = [1,2,3,4,5]
        var randomIterator = RandomIterator(collection: original, randomNumberGenerator: SeededGenerator(seed: 23))

        var result: [Int] = []
        while let next = randomIterator.next() {
            print(next)
            result.append(next)
        }

        XCTAssertEqual(original.count, result.count)
        XCTAssertEqual(result, [2, 1, 3, 4, 5])

    }


}
