**CLASS**

# `TensorData`

**Contents**

- [Properties](#properties)
  - `data`
  - `shape`
- [Methods](#methods)
  - `init(data:shape:)`

```swift
public class TensorData<T>
```

Contains tensor data information to be use for training/validation.

## Properties
### `data`

```swift
public var data: [T]
```

Tensor data as a one dimensional array

### `shape`

```swift
public let shape: [Int]
```

Shape of the tensor

## Methods
### `init(data:shape:)`

```swift
public init(data: [T], shape: [Int]) throws
```

Initialize a tensor to be used for training/validation in `SwiftSyft`
- Parameters:
  - data: tensor data as a 1D array. Must be a floating point type or an integer type
  - shape: an array of integers defining the shape of the tensor

#### Parameters

| Name | Description |
| ---- | ----------- |
| data | tensor data as a 1D array. Must be a floating point type or an integer type |
| shape | an array of integers defining the shape of the tensor |