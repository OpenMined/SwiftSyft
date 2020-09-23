import Foundation
import SyftProto

public class SyftModel {

    private let modelState: SyftProto_Execution_V1_State

    init(modelState: SyftProto_Execution_V1_State) {
        self.modelState = modelState
    }
}
