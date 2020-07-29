**CLASS**

# `SyftClient`

**Contents**

- [Methods](#methods)
  - `init(url:authToken:)`
  - `newJob(modelName:version:)`

```swift
public class SyftClient: SyftClientProtocol
```

Syft client for model-centric federated learning

## Methods

### `init(url:authToken:)`

```swift
convenience public init?(url: URL, authToken: String? = nil)
```

Initializes as `SyftClient` with a PyGrid server URL and an authentication token (if needed)

- Parameters:
  - url: Full URL to a PyGrid server (`ws`(websocket) and `http` protocols suppported)
  - authToken: PyGrid authentication token

#### Parameters

| Name      | Description                                                                   |
| --------- | ----------------------------------------------------------------------------- |
| url       | Full URL to a PyGrid server (`ws`(websocket) and `http` protocols suppported) |
| authToken | PyGrid authentication token                                                   |

### `newJob(modelName:version:)`

```swift
public func newJob(modelName: String, version: String) -> SyftJob
```

Creates a new federated learning cycle job with the given options

- Parameters:
  - modelName: Model name as it is stored in the PyGrid server you are connecting to
  - version: Version of the model (ex. 1.0)
- Returns: `SyftJob`

#### Parameters

| Name      | Description                                                           |
| --------- | --------------------------------------------------------------------- |
| modelName | Model name as it is stored in the PyGrid server you are connecting to |
| version   | Version of the model (ex. 1.0)                                        |
