//
//  TorchTrainingModule.h
//  Pods
//
//  Created by Mark Jeremiah Jimenez on 31/03/2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TensorsHolder: NSObject

@property (strong, nonatomic) NSArray<NSValue *> *tensorPointerValues;
@property (strong, nonatomic) NSArray<NSData *> *tensorData;
@property (strong, nonatomic) NSArray<NSArray<NSNumber *> *> *tensorShapes;
@property (strong, nonatomic) NSArray<NSNumber *> *types;

- (instancetype)initWithTensorPointerValues:(NSArray<NSValue *> *)tensorPointerValues
                                 tensorData:(NSArray<NSData *> *)tensorData
                               tensorShapes:(NSArray<NSArray<NSNumber *> *> *)tensorShapes
                                      types:(NSArray<NSNumber *> *)types;

@end

@interface TorchTrainingResult: NSObject

@property (nonatomic) float loss;
@property (nonatomic, strong, nonnull) NSArray<NSArray<NSNumber *> *>* updatedParams;

- (instancetype)initWithLoss:(float)loss updatedParams:(NSArray<NSArray<NSNumber *> *> *)updatedParams;

@end


@interface TorchTrainingModule : NSObject

- (instancetype)initWithFileAtPath:(NSString*)filePath
NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

//- (TorchTrainingResult *)executeWithTrainingArray:(void *)trainingDataArray
//     trainingShapes:(NSArray<NSNumber *> *)trainingDataShapes
//     trainingLabels:(void *)trainingLabelArrays
//trainingLabelShapes:(NSArray<NSNumber *> *)trainingLabelShapes
//        paramArrays:(NSArray<NSValue *> *)paramArrays
//         withShapes:(NSArray<NSArray<NSNumber *> *> *)paramShapes
//          batchSize:(void *)batchSize
//       learningRate:(void *)learningRate;

- (TorchTrainingResult *)executeWithTrainingArray:(void *)trainingDataArray
     trainingShapes:(NSArray<NSNumber *> *)trainingDataShapes
     trainingLabels:(void *)trainingLabelArrays
trainingLabelShapes:(NSArray<NSNumber *> *)trainingLabelShapes
 paramTensorsHolder:(TensorsHolder *)paramTensorsHolder
          batchSize:(void *)batchSize
       learningRate:(void *)learningRate;



- (NSArray<NSArray<NSNumber *> *> *)generateDiffFromOriginalParamArrays:(NSArray<NSValue *> *)originalParamArrays
                                                     updatedParamArrays:(NSArray<NSValue *> *)updatedParamArrays
                                                             withShapes:(NSArray<NSArray<NSNumber *> *> *)paramShapes;


@end

NS_ASSUME_NONNULL_END
