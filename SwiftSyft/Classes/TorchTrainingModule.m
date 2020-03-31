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
    return filePath;
}

@end
