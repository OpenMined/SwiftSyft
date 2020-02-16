import Foundation

public class SyftClient: SyftClientProtocol {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func newJob(modelName: String, version: String) -> SyftJob {
        return SyftJob(url: self.url, modelName: modelName, version: version)
    }
}

public class SyftJob: SyftJobProtocol {

    let url: URL
    let modelName: String
    let version: String

    public init(url: URL, modelName: String, version: String) {
        self.url = url
        self.modelName = modelName
        self.version = version
    }

    /// Request to join a federated learning cycle at "federated/cycle-request" endpoint (https://github.com/OpenMined/PyGrid/issues/445)
    public func start() {

        // TODO: Execute an authentication request to PyGrid:
        // URL endpoint: POST federated/authenticate
        // TODO: Retry this request if failed

        // TODO: Chain a successful authenticate request to an FL Worker Cycle Request
        // URL endpoint: POST federated/cycle-request
        // Params: JSON Body . Refer to `CycleRequest` struct in FederatedLearningMessages

        // TODO: If both requests are successful above
        // Create download request for the model, plan and protocol(if available)

        // TODO: Save a `Subscriber` in a property that is fired as long as the requests above are successful.

    }

    public func onReady(execute: () -> Void) {

        // TODO: Subscribe to the `Subscriber` property created in `start()` and
        // execute the block above once the subscriber is fired
    }

    /// Report the results of the learning cycle to PyGrid at "federated
    public func report() {
        // TODO: Send job report after onReady finishes execution
        //
    }

}
