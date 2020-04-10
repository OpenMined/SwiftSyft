//
//  TorchTrainingModule.m
//  Pods
//
//  Created by Mark Jeremiah Jimenez on 31/03/2020.
//

#import "TorchTrainingModule.h"

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

- (NSArray<NSArray<NSNumber *> *> *)executeWithTrainingArray:(void *)trainingDataArray
                                              trainingShapes:(NSArray<NSNumber *> *)trainingDataShapes
                                              trainingLabels:(void *)trainingLabelArrays
                                         trainingLabelShapes:(NSArray<NSNumber *> *)trainingLabelShapes
                                                 paramArrays:(NSArray<NSValue *> *)paramArrays
                                                  withShapes:(NSArray<NSArray<NSNumber *> *> *)paramShapes
                                                   batchSize:(void *)batchSize
                                                learningRate:(void *)learningRate {

//    torch::jit::script::Module planModel = torch::jit::load(filepath.UTF8String);
//
//    std::vector<torch::jit::IValue> modelArgs;
//
//    // Push training data vectors to model args
//    std::vector<int64_t> trainingDataVectorShape;
//    for (NSNumber *dim in trainingDataShapes) {
//        trainingDataVectorShape.push_back([dim integerValue]);
//    }
//
//    at::Tensor trainingDataTensor = torch::from_blob(trainingDataArray, trainingDataVectorShape, at::kFloat);
//    modelArgs.push_back(trainingDataTensor);
//
//    modelArgs.push_back(torch::randn({10, 784}));
//
//    // Push training label vectors
//
//    std::vector<int64_t> trainingLabelVectorShape;
//    for (NSNumber *dim in trainingLabelShapes) {
//        trainingLabelVectorShape.push_back([dim integerValue]);
//    }
//
//    at::Tensor trainingLabelsTensor = torch::from_blob(trainingLabelArrays, trainingLabelVectorShape, at::kInt);
//
//    modelArgs.push_back(trainingLabelsTensor);
//
//    // Push learning rate and batch size
//    auto batchSizeTensor = torch::from_blob(batchSize, {1}, at::kInt);
//    auto learningRateTensor = torch::from_blob(learningRate, {1}, at::kInt);
//    modelArgs.push_back(batchSizeTensor);
//    modelArgs.push_back(learningRateTensor);
//
//    // Push model training vectors
//
//    NSInteger paramArrayLength = [paramArrays count];
//
//    for (NSInteger index = 0; index < paramArrayLength; index++) {
//        NSValue *tensorPointerValue = paramArrays[index];
//        void *tensorPointer = [tensorPointerValue pointerValue];
//
//        NSArray<NSNumber *> *shape = paramShapes[index];
//        std::vector<int64_t> shapes;
//        for (NSNumber *dim in shape) {
//            int dimInt = [dim intValue];
//            shapes.push_back(dimInt);
//        }
//
//        at::Tensor paramsTensor = torch::from_blob(tensorPointer, shapes, at::kFloat);
//
//        modelArgs.push_back(paramsTensor);
//
//    }
//
//    std::cout << "outputs" << std::endl;
//
//    auto outputs = planModel.forward(modelArgs);
//
//    std::cout << outputs << std::endl;

    // Code to temporarily generate updated params to test model reporting
    NSMutableArray *diffArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [paramArrays count]; i++) {

        NSMutableArray *diff = [[NSMutableArray alloc] init];
        NSArray *shape = paramShapes[i];
        NSInteger length = 1;
        for (NSNumber *dim in shape) {
            length = length * [dim intValue];
        }

        for (int x = 0; x < length; x++) {
            float val = ((float)arc4random() / UINT32_MAX);
            [diff addObject:[NSNumber numberWithFloat:val]];
        }

        [diffArray addObject:[diff copy]];

    }

    return [diffArray copy];

}


@end
