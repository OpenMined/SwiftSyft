//
//  TorchTrainingModule.m
//  Pods
//
//  Created by Mark Jeremiah Jimenez on 31/03/2020.
//

#import "TorchTrainingModule.h"
#include <LibTorch/LibTorch.h>

std::map<int, at::ScalarType> tensorTypeMap = {{1, at::kInt}, {2, at::kInt}, {3, at::kLong}, {4, at::kFloat}, {5, at::kDouble}};

@implementation TorchTrainingResult

- (instancetype)initWithLoss:(float)loss
               updatedParams:(NSArray<NSArray<NSNumber *> *> *)updatedParams {

    self = [self init];
    if (self) {
        _loss = loss;
        _updatedParams = updatedParams;
    }
    return self;

}
@end

@interface TorchTrainingModule()

@property (strong, nonatomic) NSString *torchScriptFilePath;

@end

@implementation TorchTrainingModule

- (instancetype)initWithFileAtPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _torchScriptFilePath = filePath;
    }
    return self;
}

- (TorchTrainingResult *)executeWithTrainingArray:(void *)trainingDataArray
                                              trainingShapes:(NSArray<NSNumber *> *)trainingDataShapes
                                              trainingLabels:(void *)trainingLabelArrays
                                         trainingLabelShapes:(NSArray<NSNumber *> *)trainingLabelShapes
                                                 paramArrays:(NSArray<NSValue *> *)paramArrays
                                                  withShapes:(NSArray<NSArray<NSNumber *> *> *)paramShapes
                                                   batchSize:(void *)batchSize
                                                learningRate:(void *)learningRate {

    torch::jit::script::Module planModel = torch::jit::load(self.torchScriptFilePath.UTF8String);

    std::vector<torch::jit::IValue> modelArgs;

    // Push training data vectors to model args
    std::vector<int64_t> trainingDataVectorShape;
    for (NSNumber *dim in trainingDataShapes) {
        trainingDataVectorShape.push_back([dim integerValue]);
    }

    at::Tensor trainingDataTensor = torch::from_blob(trainingDataArray, trainingDataVectorShape, at::kFloat);
    modelArgs.push_back(trainingDataTensor);

    // Push training label vectors

    std::vector<int64_t> trainingLabelVectorShape;
    for (NSNumber *dim in trainingLabelShapes) {
        trainingLabelVectorShape.push_back([dim integerValue]);
    }

    at::Tensor trainingLabelsTensor = torch::from_blob(trainingLabelArrays, trainingLabelVectorShape, at::kFloat);

    modelArgs.push_back(trainingLabelsTensor);

    // Push learning rate and batch size
    auto batchSizeTensor = torch::from_blob(batchSize, {1}, at::kInt);
    auto learningRateTensor = torch::from_blob(learningRate, {1}, at::kFloat);
    modelArgs.push_back(batchSizeTensor);
    modelArgs.push_back(learningRateTensor);

    // Push model training vectors

    NSInteger paramArrayLength = [paramArrays count];

    for (NSInteger index = 0; index < paramArrayLength; index++) {
        NSValue *tensorPointerValue = paramArrays[index];
        void *tensorPointer = [tensorPointerValue pointerValue];

        NSArray<NSNumber *> *shape = paramShapes[index];
        std::vector<int64_t> shapes;
        for (NSNumber *dim in shape) {
            int dimInt = [dim intValue];
            shapes.push_back(dimInt);
        }

        at::Tensor paramsTensor = torch::from_blob(tensorPointer, shapes, at::kFloat);

        modelArgs.push_back(paramsTensor);

    }

    auto outputs = planModel.forward(modelArgs);

    auto tupleOutputs = outputs.toTuple();

    // output is loss, metric, *params
    NSInteger outputsLength = 2 + [paramArrays count];

    // Array to store new params
    NSMutableArray *newParamsArray = [[NSMutableArray alloc] init];

    float loss = 0;
    // Copy new params tensor to an NSArray
    for (NSInteger i = 0; i < outputsLength; i++) {

        // Print loss
        if (i == 0) {
            auto lossTensor = tupleOutputs->elements()[i].toTensor();
            loss = lossTensor.item<float>();
            continue;
        }

        // Pring metric
        if (i == 1) {
            auto metric = tupleOutputs->elements()[i].toTensor();
            continue;
        }

        // Add params to array of params
        NSInteger paramsIndex = i-2;
        NSArray *paramShape = paramShapes[paramsIndex];
        NSInteger length = 1;
        for (NSNumber *dim in paramShape) {
            length = length * [dim intValue];
        }

        auto paramTensor = tupleOutputs->elements()[i].toTensor();
        float *floatBuffer = paramTensor.data_ptr<float>();

        NSMutableArray *newParam = [[NSMutableArray alloc] init];
        for (int x = 0; x < length; x++) {
            [newParam addObject:@(floatBuffer[x])];
        }

        [newParamsArray addObject:[newParam copy]];

    }

    TorchTrainingResult *result = [[TorchTrainingResult alloc] initWithLoss:loss updatedParams:[newParamsArray copy]];

    return result;

}

- (NSArray<NSArray<NSNumber *> *> *)generateDiffFromOriginalParamArrays:(NSArray<NSValue *> *)originalParamArrays
                                                     updatedParamArrays:(NSArray<NSValue *> *)updatedParamArrays
                                                             withShapes:(NSArray<NSArray<NSNumber *> *> *)paramShapes {


    NSMutableArray *diffArrays = [[NSMutableArray alloc] init];
    NSInteger paramsLength = [originalParamArrays count];

    for (NSInteger index=0; index < paramsLength; index++) {
        NSValue *originalParamValue = originalParamArrays[index];
        void *originalParamPointer = [originalParamValue pointerValue];

        NSValue *updatedParamValue = updatedParamArrays[index];
        void *updatedParamPointer = [updatedParamValue pointerValue];

        NSArray<NSNumber *> *shape = paramShapes[index];
        std::vector<int64_t> shapes;
        for (NSNumber *dim in shape) {
            int dimInt = [dim intValue];
            shapes.push_back(dimInt);
        }

        at::Tensor originalParamsTensor = torch::from_blob(originalParamPointer, shapes, at::kFloat);

        at::Tensor updatedParamsTensor = torch::from_blob(updatedParamPointer, shapes, at::kFloat);

        auto diffTensor = originalParamsTensor - updatedParamsTensor;

        float* floatBuffer = diffTensor.data_ptr<float>();

        // Get complete length of tensor
        NSInteger length = 1;
        for (NSNumber *dim in shape) {
            length = length * [dim intValue];
        }

        // Copy tensor contents to an NSArray
        NSMutableArray *diffArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < length; i++) {
            [diffArray addObject:@(floatBuffer[i])];
        }

        [diffArrays addObject:[diffArray copy]];

    }

    return [diffArrays copy];
}


@end
