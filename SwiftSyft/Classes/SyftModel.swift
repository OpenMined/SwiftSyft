import Foundation
import SyftProto

public class SyftModel {

    private let modelState: SyftProto_Execution_V1_State
    public var originalParamTensors: [TorchTensor]?
    private var _updatedParams: [TorchTensor]?

    public var paramTensorsForTraining: [TorchTensor]? {
        get {
            if let paramTensors = self._updatedParams,
               !paramTensors.isEmpty {

                return self._updatedParams

            } else {

                return originalParamTensors

            }
        } set {
            self._updatedParams = newValue
        }
    }

    init(modelState: SyftProto_Execution_V1_State) {
        self.modelState = modelState
        self.originalParamTensors = try? self.modelState.getTorchTensors()
    }

    public func generateDiffData() -> Data? {

        guard let originalParams = self.originalParamTensors,
              let newParams = self._updatedParams,
              let difference = originalParams - newParams else {
            return nil
        }

        let diffArray = difference.map { paramTensor -> [Float] in
            return paramTensor.toArray().map { $0.floatValue }
        }

        let diffState = self.modelState.updateWithParams(params: diffArray)

        return try? diffState.serializedData()

    }

}
