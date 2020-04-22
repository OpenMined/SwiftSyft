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

    //  swiftlint:disable force_cast
    public func execute(trainingData: TrainingData, validationData: ValidationData, clientConfig: FederatedClientConfig) {

        var trainingDataCopy = trainingData
        var validationDataCopy = validationData

        let (paramShapes, paramTensorPointers, _) = self.updatedModelState.getTensorData()

        var batchSizeArray = [clientConfig.batchSize]
        var learningRateArray = [clientConfig.learningRate]

        let updatedParams = self.trainingModule.execute(withTrainingArray: &trainingDataCopy.data,
                                    trainingShapes: trainingData.shape as [NSNumber],
                                    trainingLabels: &validationDataCopy.data,
                                    trainingLabelShapes: validationDataCopy.shape as [NSNumber],
                                    paramArrays: paramTensorPointers,
                                    withShapes: (paramShapes as NSArray) as! [[NSNumber]],
                                    batchSize: &batchSizeArray, learningRate: &learningRateArray)

        let updatedParamsFloatArray = updatedParams.map { diff -> [Float32] in
            return diff.map { $0.floatValue }
        }

        // Update model state
        self.updatedModelState = self.updatedModelState.updateWithParams(params: updatedParamsFloatArray)

        //         Free param buffer pointers
        for pointerValue in paramTensorPointers {
            if let pointer = pointerValue.pointerValue {
                pointer.deallocate()
            }
        }

    }
    // swiftlint:enable force_cast

    public func generateDiffData() throws -> Data {

        let (originalParamShapes, originalParamTensorPointers, _) = self.originalModelState.getTensorData()
        let (_, updatedParamTensorPointers, _) = self.updatedModelState.getTensorData()

        defer {
            // Free param buffer pointers
            for pointerValue in originalParamTensorPointers {
                if let pointer = pointerValue.pointerValue {
                    pointer.deallocate()
                }
            }

            // Free param buffer pointers
            for pointerValue in updatedParamTensorPointers {
                if let pointer = pointerValue.pointerValue {
                    pointer.deallocate()
                }
            }
        }

        let diff = self.trainingModule.generateDiff(fromOriginalParamArrays: originalParamTensorPointers,
                                                    updatedParamArrays: updatedParamTensorPointers, withShapes: originalParamShapes as [[NSNumber]])

        let diffFloatArray = diff.map { diff -> [Float] in
            return diff.map { Float(truncating: $0) }
        }

        let diffState = self.updatedModelState.updateWithParams(params: diffFloatArray)

        return try diffState.serializedData()

    }

}
