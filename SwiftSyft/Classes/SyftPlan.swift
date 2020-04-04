import Foundation
import SyftProto

public struct TrainingData {

    let data: [Double]
    let shape: [Int]

}

public struct ValidationData {

    let data: [Int]
    let shape: [Int]

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
