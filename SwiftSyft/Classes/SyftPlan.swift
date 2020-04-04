import Foundation
import SyftProto

public struct TrainingData {

    public let data: [Float]
    public let shape: [Int]

    public init(data: [Float], shape: [Int]) {
        self.data = data
        self.shape = shape
    }
}

public struct ValidationData {

    public let data: [Float]
    public let shape: [Int]

    public init(data: [Float], shape: [Int]) {
        self.data = data
        self.shape = shape
    }
}

public class SyftPlan {

    private let trainingModule: TorchTrainingModule
    private let modelState: SyftProto_Execution_V1_State

    init(trainingModule: TorchTrainingModule, modelState: SyftProto_Execution_V1_State) {
        self.trainingModule = trainingModule
        self.modelState = modelState
    }

    public func execute(trainingData: TrainingData, validationData: ValidationData) {

    }

}
