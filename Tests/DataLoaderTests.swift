import XCTest
import GameplayKit
@testable import SwiftSyft

// https://stackoverflow.com/questions/54821659/swift-4-2-seeding-a-random-number-generator
class SeededGenerator: RandomNumberGenerator {
    let seed: UInt64
    private let generator: GKMersenneTwisterRandomSource
    convenience init() {
        self.init(seed: 0)
    }
    init(seed: UInt64) {
        self.seed = seed
        generator = GKMersenneTwisterRandomSource(seed: seed)
    }
    func next<T>(upperBound: T) -> T where T : FixedWidthInteger, T : UnsignedInteger {
        return T(abs(generator.nextInt(upperBound: Int(upperBound))))
    }
    func next<T>() -> T where T : FixedWidthInteger, T : UnsignedInteger {
        return T(abs(generator.nextInt()))
    }
}

class DataLoaderTests: XCTestCase {

    func testRandomIterator() {

        let original = [1,2,3,4,5]
        var randomIterator = RandomIterator(collection: original, randomNumberGenerator: SeededGenerator(seed: 23))

        var result: [Int] = []
        while let next = randomIterator.next() {
            result.append(next)
        }

        XCTAssertEqual(original.count, result.count)
        XCTAssertEqual(result, [3, 4, 2, 5, 1])

    }

}
