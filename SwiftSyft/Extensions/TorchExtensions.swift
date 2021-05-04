import Foundation

public extension TorchTensor {

    static func - (lhs: TorchTensor, rhs: TorchTensor) throws -> TorchTensor {
        return try lhs.sub(rhs)
    }

    static func + (lhs: TorchTensor, rhs: TorchTensor) throws -> TorchTensor {
        return try lhs.add(rhs)
    }

    static func * (lhs: TorchTensor, rhs: TorchTensor) throws -> TorchTensor {
        return try lhs.mul(rhs)
    }

    static func / (lhs: TorchTensor, rhs: TorchTensor) throws -> TorchTensor {
        return try lhs.div(rhs)
    }

}

public extension Array where Element == TorchTensor {
    static func -(lhs: [TorchTensor], rhs: [TorchTensor]) -> [TorchTensor]? {

        guard lhs.count == rhs.count else {
            return nil
        }

        var differenceTensors: [TorchTensor]? = []

        for index in 0..<lhs.count {

            let leftTensor = lhs[index]
            let rightTensor = rhs[index]

            guard let difference = try? leftTensor - rightTensor else {
                return nil
            }

            differenceTensors?.append(difference)

        }

        return differenceTensors

    }
}

public extension TorchTensor {

    static func new(array: [Int8], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<Int8>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .char) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [UInt8], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .byte) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [UInt32], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<UInt32>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .int) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [Int32], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<Int32>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .int) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [Int64], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<Int64>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .long) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [Float], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<Float>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .float) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [Double], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<Double>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .double) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

    static func new(array: [Bool], size: [Int]) -> TorchTensor? {

        var copy = array
        let tensorPointer = UnsafeMutablePointer<Bool>.allocate(capacity: copy.count)
        tensorPointer.initialize(from: &copy, count: copy.count)

        guard let tensor = TorchTensor.new(withData: tensorPointer, size: size as [NSNumber], type: .bool) else {
            return nil
        }

        tensor.pointerValue = NSValue(pointer: tensorPointer)
        tensor.deinitBlock = {
            tensorPointer.deallocate()
        }

        return tensor

    }

}
