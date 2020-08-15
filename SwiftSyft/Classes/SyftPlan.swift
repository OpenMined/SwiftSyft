import Foundation
import SyftProto

struct TensorError: LocalizedError {
    var localizedDescription: String
}

/// Contains tensor data information to be use for training/validation.
public class TensorData<T> {

    /// Tensor data as a one dimensional array
    public var data: [T]

    /// Shape of the tensor
    public let shape: [Int]
    let tensorType: TensorType

    let typeMapping: [ObjectIdentifier: TensorType] = [ObjectIdentifier(Int.self): TensorType.int32,
                                                ObjectIdentifier(Int32.self): TensorType.int32,
                                                ObjectIdentifier(UInt32.self): TensorType.uint32,
                                                ObjectIdentifier(Int64.self): TensorType.int64,
                                                ObjectIdentifier(Float.self): TensorType.float,
                                                ObjectIdentifier(Double.self): TensorType.double,
                                                ObjectIdentifier(Bool.self): TensorType.bool]

    /// Initialize a tensor to be used for training/validation in `SwiftSyft`
    /// - Parameters:
    ///   - data: tensor data as a 1D array. Must be a floating point type or an integer type
    ///   - shape: an array of integers defining the shape of the tensor
    public init(data: [T], shape: [Int]) throws {
        self.data = data
        self.shape = shape
        if let tensorType = typeMapping[ObjectIdentifier(type(of: data).Element.self)] {
            self.tensorType = tensorType
        } else {
            throw TensorError(localizedDescription: "Unsupported type selected for array. Please use Int, Int64, Float or Double")
        }
    }
}

/// Tensor data used for training only. To be passed to `SyftPlan.execute()`
public class TrainingData<T>: TensorData<T> { }

/// Tensor data used for validation only. To be passed to `SyftPlan.execute()`
public class ValidationData<T>: TensorData<T> { }

/// Holds the training script to be used for training your data and generating diffs
public class SyftPlan {

    private let trainingModule: TorchTrainingModule
    private var originalModelState: SyftProto_Execution_V1_State
    private var updatedModelState: SyftProto_Execution_V1_State

    init(trainingModule: TorchTrainingModule, modelState: SyftProto_Execution_V1_State) {
        self.trainingModule = trainingModule
        self.originalModelState = modelState
        self.updatedModelState = modelState
    }

    /// Executes the model received from PyGrid on your training and validation data.
    /// Loop through your entire training data and call this method to update the model parameters received from PyGrid.
    /// - Parameters:
    ///   - trainingData: tensor data used for training
    ///   - validationData: tensor data used for validation
    ///   - clientConfig: contains training parameters (batch size and learning rate)
    @discardableResult public func execute<T, U>(trainingData: TrainingData<T>, validationData: ValidationData<U>, clientConfig: FederatedClientConfig) -> Float {

        var trainingDataCopy = trainingData
        var validationDataCopy = validationData

        let stateTensorsHolder = self.updatedModelState.getTensorData()

        var batchSizeArray = [clientConfig.batchSize]
        var learningRateArray = [clientConfig.learningRate]

        let trainingResult = self.trainingModule.execute(withTrainingArray: &trainingDataCopy.data,
                                                         trainingShapes: trainingDataCopy.shape as [NSNumber],
                                                         trainingDataType: trainingDataCopy.tensorType.rawValue,
                                                         trainingLabels: &validationDataCopy.data,
                                                         trainingLabelShapes: validationDataCopy.shape as [NSNumber],
                                                         trainingLabelType: validationDataCopy.tensorType.rawValue,
                                                         paramTensorsHolder: stateTensorsHolder,
                                                         batchSize: &batchSizeArray,
                                                         learningRate: &learningRateArray)

        let updatedParamsFloatArray = trainingResult.updatedParams.map { diff -> [Float32] in
            return diff.map { $0.floatValue }
        }

        // Update model state
        self.updatedModelState = self.updatedModelState.updateWithParams(params: updatedParamsFloatArray)

        //         Free param buffer pointers
        for pointerValue in stateTensorsHolder.tensorPointerValues {
            if let pointer = pointerValue.pointerValue {
                pointer.deallocate()
            }
        }

        return trainingResult.loss

    }
    // swiftlint:enable force_cast

    /// Calculates difference between the original model parameters received from PyGrid and the updated model parameters generated from running this plan
    /// on your training and validation data. This diff data will be passed to the model report closure to send it to PyGrid.
    public func generateDiffData() throws -> Data {

        let originalParamsHolder = self.originalModelState.getTensorData()
        let updatedParamsHolder = self.updatedModelState.getTensorData()

        defer {
            // Free param buffer pointers
            for pointerValue in originalParamsHolder.tensorPointerValues {
                if let pointer = pointerValue.pointerValue {
                    pointer.deallocate()
                }
            }

            // Free param buffer pointers
            for pointerValue in updatedParamsHolder.tensorPointerValues {
                if let pointer = pointerValue.pointerValue {
                    pointer.deallocate()
                }
            }
        }

        let diff = self.trainingModule.generateDiff(fromOriginalParamArrays: originalParamsHolder.tensorPointerValues,
                                                    updatedParamArrays: updatedParamsHolder.tensorPointerValues, withShapes: originalParamsHolder.tensorShapes)

        let diffFloatArray = diff.map { diff -> [Float] in
            return diff.map { Float(truncating: $0) }
        }

        let diffState = self.updatedModelState.updateWithParams(params: diffFloatArray)

        return try diffState.serializedData()

    }

}
