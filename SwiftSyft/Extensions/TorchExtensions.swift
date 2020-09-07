import Foundation

extension TorchTensor {
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
