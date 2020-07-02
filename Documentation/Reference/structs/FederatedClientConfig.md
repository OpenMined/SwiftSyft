**STRUCT**

# `FederatedClientConfig`

**Contents**

- [Properties](#properties)
  - `name`
  - `version`
  - `batchSize`
  - `learningRate`
  - `maxUpdates`

```swift
public struct FederatedClientConfig: Codable
```

Configuration value that contains details regarding the model used for the training cycle
and the training configuration.

## Properties
### `name`

```swift
public let name: String
```

Name of the model received from PyGrid

### `version`

```swift
public let version: String
```

Version of the model received from PyGrid

### `batchSize`

```swift
public let batchSize: Int
```

Size of batch used for training the model

### `learningRate`

```swift
public let learningRate: Float
```

Learning rate used for training the model

### `maxUpdates`

```swift
public let maxUpdates: Int
```
