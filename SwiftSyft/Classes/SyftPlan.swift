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

        let updatedParamsFloatArray = updatedParams.map { diff -> [Float] in
            return diff.map { Float(truncating: $0) }
        }

        // Update model state
        var updatedModelState = self.updatedModelState

        let updatedParamTensors = zip(updatedModelState.tensors, updatedParamsFloatArray).map { args -> SyftProto_Execution_V1_StateTensor in

                let (stateTensor, paramsArray) = args
                var tensorData = SyftProto_Types_Torch_V1_TensorData()
                tensorData.contentsFloat32 = paramsArray as [Float32]
                var copyStateTensor = stateTensor
                copyStateTensor.torchTensor.contentsData = tensorData
                return copyStateTensor

            }

        updatedModelState.tensors = updatedParamTensors
        self.updatedModelState = updatedModelState
    }
    // swiftlint:enable force_cast

}
