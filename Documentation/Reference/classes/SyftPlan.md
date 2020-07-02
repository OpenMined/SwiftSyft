**CLASS**

# `SyftPlan`

**Contents**

- [Methods](#methods)
  - `execute(trainingData:validationData:clientConfig:)`
  - `generateDiffData()`

```swift
public class SyftPlan
```

Holds the training script to be used for training your data and generating diffs

## Methods
### `execute(trainingData:validationData:clientConfig:)`

```swift
@discardableResult public func execute<T, U>(trainingData: TrainingData<T>, validationData: ValidationData<U>, clientConfig: FederatedClientConfig) -> Float
```

Executes the model received from PyGrid on your training and validation data.
Loop through your entire training data and call this method to update the model parameters received from PyGrid.
- Parameters:
  - trainingData: tensor data used for training
  - validationData: tensor data used for validation
  - clientConfig: contains training parameters (batch size and learning rate)

#### Parameters

| Name | Description |
| ---- | ----------- |
| trainingData | tensor data used for training |
| validationData | tensor data used for validation |
| clientConfig | contains training parameters (batch size and learning rate) |

### `generateDiffData()`

```swift
public func generateDiffData() throws -> Data
```

Calculates difference between the original model parameters received from PyGrid and the updated model parameters generated from running this plan
on your training and validation data. This diff data will be passed to the model report closure to send it to PyGrid.
