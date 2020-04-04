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

    private let planScript: SyftProto_Types_Torch_V1_ScriptModule
    private let modelState: SyftProto_Execution_V1_State

    init(planScript: SyftProto_Types_Torch_V1_ScriptModule, modelState: SyftProto_Execution_V1_State) {
        self.planScript = planScript
        self.modelState = modelState
    }

    public func execute(trainingData: TrainingData, validationData: ValidationData) {

    }

}
