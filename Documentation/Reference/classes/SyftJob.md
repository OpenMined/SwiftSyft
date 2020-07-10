**CLASS**

# `SyftJob`

**Contents**

- [Methods](#methods)
  - `start(chargeDetection:wifiDetection:)`
  - `onReady(execute:)`
  - `onError(execute:)`
  - `onRejected(execute:)`

```swift
public class SyftJob: SyftJobProtocol
```

Represents a single training cycle done by the client

## Methods
### `start(chargeDetection:wifiDetection:)`

```swift
public func start(chargeDetection: Bool = true, wifiDetection: Bool = true)
```

Starts the job executing the following actions:
1. Meters connection speed to PyGrid
2. Registers into training cycle on PyGrid
3. Retrieves cycle and client parameters.
4. Downloads Plans, Model and Protocols.
5. Triggers `onReady` handler
- Parameters:
  - chargeDetection: Specifies whether to check if device is charging before continuing job execution. Default is `true`.
  - wifiDetection: Specifies whether to have wifi connection before continuing job execution. Default is `true`.

#### Parameters

| Name | Description |
| ---- | ----------- |
| chargeDetection | Specifies whether to check if device is charging before continuing job execution. Default is `true`. |
| wifiDetection | Specifies whether to have wifi connection before continuing job execution. Default is `true`. |

### `onReady(execute:)`

```swift
public func onReady(execute: @escaping (_ plan: SyftPlan, _ clientConfig: FederatedClientConfig, _ report: ModelReport) -> Void)
```

Registers a closure to execute when the job is accepted into a training cycle.
- Parameter execute: Closure that accepts the training plan (`SyftPlan`), training configuration (`FederatedClientConfig`) and reporting closure (`ModelReport`).
All of these objects will be used during training.
- parameter plan: `SyftPlan` use this to train your model and generate diffs
- parameter clientConfig: contains training configuration such as batch size and learning rate.
- parameter report: closure that accepts diffs as `Data` and sends them to PyGrid.

#### Parameters

| Name | Description |
| ---- | ----------- |
| execute | Closure that accepts the training plan (`SyftPlan`), training configuration (`FederatedClientConfig`) and reporting closure (`ModelReport`). All of these objects will be used during training. |
| plan | `SyftPlan` use this to train your model and generate diffs |
| clientConfig | contains training configuration such as batch size and learning rate. |
| report | closure that accepts diffs as `Data` and sends them to PyGrid. |

### `onError(execute:)`

```swift
public func onError(execute: @escaping (_ error: Error) -> Void)
```

Registers a closure to execute whenever an error occurs during training cycle
- Parameter execute: closure to execute during training cycle
- parameter error: contains information about error that occurred

#### Parameters

| Name | Description |
| ---- | ----------- |
| execute | closure to execute during training cycle |
| error | contains information about error that occurred |

### `onRejected(execute:)`

```swift
public func onRejected(execute: @escaping (_ timeout: TimeInterval?) -> Void)
```

Registers a closure to execute whenever an error occurs during training cycle
- Parameter execute: closure to execute during training cycle
- parameter timeout: how long you need to wait before trying again

#### Parameters

| Name | Description |
| ---- | ----------- |
| execute | closure to execute during training cycle |
| timeout | how long you need to wait before trying again |