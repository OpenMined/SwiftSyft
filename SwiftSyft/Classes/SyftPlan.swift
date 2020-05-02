import Foundation
import SyftProto

public struct TrainingData {

    public var data: [Float]
    public let shape: [Int]

    public init(data: [Float], shape: [Int]) {
        self.data = data
        self.shape = shape
    }
}

public struct ValidationData {

    public var data: [Float]
    public let shape: [Int]

    public init(data: [Float], shape: [Int]) {
        self.data = data
        self.shape = shape
    }
}

public class SyftPlan {

    private let trainingModule: TorchTrainingModule
    private var originalModelState: SyftProto_Execution_V1_State
    private var updatedModelState: SyftProto_Execution_V1_State

    init(trainingModule: TorchTrainingModule, modelState: SyftProto_Execution_V1_State) {
        self.trainingModule = trainingModule
        self.originalModelState = modelState
        self.updatedModelState = modelState
    }

    @discardableResult public func execute(trainingData: TrainingData, validationData: ValidationData, clientConfig: FederatedClientConfig) -> Float {

        var trainingDataCopy = trainingData
        var validationDataCopy = validationData

        let stateTensorsHolder = self.updatedModelState.getTensorData()

        var batchSizeArray = [clientConfig.batchSize]
        var learningRateArray = [clientConfig.learningRate]

        let trainingResult = self.trainingModule.execute(withTrainingArray: &trainingDataCopy.data,
                                    trainingShapes: trainingData.shape as [NSNumber],
                                    trainingLabels: &validationDataCopy.data,
                                    trainingLabelShapes: validationDataCopy.shape as [NSNumber],
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
