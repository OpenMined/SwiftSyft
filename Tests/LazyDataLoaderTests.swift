//
//  LazyDataLoaderTests.swift
//  OpenMinedSwiftSyft-Unit-Tests
//
//  Created by Rohith Pudari on 08/11/20.
//

import XCTest
import GameplayKit
@testable import SwiftSyft

// LibTorch tensor operations (ex. torch::cat) currently not working in
// test target with error message: "PyTorch is not linked with support for cpu devices".
// Will wait for these operations to work before adding more tests.

class LazyDataLoaderTests: XCTestCase {

    func testDefaultIterator() {

        let original = [1,2,3,4,5]
        var Iterator = original.makeIterator()

        var result: [Int] = []
        while let next = Iterator.next() {
            print(next)
            result.append(next)
        }

        XCTAssertEqual(original.count, result.count)
        XCTAssertEqual(result, [1,2,3,4,5])

    }


}
