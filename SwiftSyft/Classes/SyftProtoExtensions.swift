//
//  Extensions.swift
//  Torch-Proto-Practice
//
//  Created by Mark Jeremiah Jimenez on 19/03/2020.
//  Copyright © 2020 OpenMined. All rights reserved.
//

import Foundation
import SyftProto

extension SyftProto_Execution_V1_State {

    // swiftlint:disable large_tuple
    func getTensorData() -> (shapes: [[Int32]],
                             tensorPointers: [NSValue],
                             tensorData: [Data]) {

        var torchTensors: [SyftProto_Types_Torch_V1_TorchTensor] = []
        var torchTensorsCount = 0
        for tensor in self.tensors {
            torchTensorsCount += 1
            switch tensor.tensor {
            case .torchParam(let torchParameter):
                torchTensors.append(torchParameter.tensor)
            case .torchTensor(let torchTensor):
                torchTensors.append(torchTensor)
            case nil:
                break
            }
        }

        var shapes: [[Int32]] = []
        var tensorData: [Data] = []
        var tensorPointerArray: [NSValue] = []

        for torchTensor in torchTensors {
            switch torchTensor.contents {
            case .contentsData(let tensorHolder):
                shapes.append(tensorHolder.shape.dims)
                if let tensorPointerNSValue = tensorHolder.tensorPointerNSValue {
                    tensorPointerArray.append(tensorPointerNSValue)
                }
            case .contentsBin(let data):
                tensorData.append(data)
            case nil:
                break
            }
        }

        return (shapes, tensorPointerArray, tensorData)

    }
}

extension SyftProto_Types_Torch_V1_TensorData {
    var tensorPointerNSValue: NSValue? {
        if !contentsUint8.isEmpty {
            var copy = contentsUint8
            let tensorPointer = UnsafeMutablePointer<UInt32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsInt8.isEmpty {
            var copy = contentsInt8
            let tensorPointer = UnsafeMutablePointer<Int32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsInt16.isEmpty {
            var copy = contentsInt16
            let tensorPointer = UnsafeMutablePointer<Int32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsInt32.isEmpty {
            var copy = contentsInt32
            let tensorPointer = UnsafeMutablePointer<Int32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsInt64.isEmpty {
            var copy = contentsInt64
            let tensorPointer = UnsafeMutablePointer<Int64>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsFloat16.isEmpty {
            var copy = contentsFloat16
            let tensorPointer = UnsafeMutablePointer<Float>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsFloat32.isEmpty {
            var copy = contentsFloat32
            let tensorPointer = UnsafeMutablePointer<Float32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsFloat64.isEmpty {
            var copy = contentsFloat64
            let tensorPointer = UnsafeMutablePointer<Double>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsBool.isEmpty {
            var copy = contentsBool
            let tensorPointer = UnsafeMutablePointer<Bool>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsQint8.isEmpty {
            var copy = contentsQint8
            let tensorPointer = UnsafeMutablePointer<Int32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsQuint8.isEmpty {
            var copy = contentsQuint8
            let tensorPointer = UnsafeMutablePointer<UInt32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsQint32.isEmpty {
            var copy = contentsQint32
            let tensorPointer = UnsafeMutablePointer<Int32>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else if !contentsBfloat16.isEmpty {
            var copy = contentsBfloat16
            let tensorPointer = UnsafeMutablePointer<Float>.allocate(capacity: copy.count)
            tensorPointer.initialize(from: &copy, count: copy.count)
            return NSValue(pointer: tensorPointer)
        } else {
            return nil
        }

    }
}

extension SyftProto_Execution_V1_State {
    func updateWithParams(params: [[Float]]) -> SyftProto_Execution_V1_State {

        var copy = self

        let updatedParamTensors = zip(copy.tensors, params).map { args -> SyftProto_Execution_V1_StateTensor in

                let (stateTensor, paramsArray) = args
                var copyStateTensor = stateTensor
                var tensorDataCopy = copyStateTensor.torchTensor.contentsData
                tensorDataCopy.contentsFloat32 = paramsArray as [Float32]
                copyStateTensor.torchTensor.contentsData = tensorDataCopy
                return copyStateTensor

            }

        copy.tensors = updatedParamTensors

        return copy

    }
}
