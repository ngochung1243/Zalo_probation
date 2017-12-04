//
//  HMURLUploadTask.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^HMUploadProgressBlock)(float progress);
typedef void (^HMUploadCompletionBlock)(NSURLResponse * _Nonnull reponse, NSError * _Nullable error);

@class HMURLUploadTask;

@protocol HMURLUploadDelegate <NSObject>

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;

@end

@interface HMURLUploadTask : NSObject

@property(nonatomic) NSUInteger taskIdentifier;

@property(weak, nonatomic) NSURLSessionUploadTask * _Nullable uploadTask;
@property(strong, nonatomic) HMUploadProgressBlock _Nullable progressBlock;
@property(strong, nonatomic) HMUploadCompletionBlock _Nullable completionBlock;
@property(nonatomic) float uploadProgress;
@property(weak, nonatomic) id<HMURLUploadDelegate> delegate;

- (instancetype _Nullable)initWithUploadTask:(NSURLSessionUploadTask * _Nonnull)task;

- (void)resume;
- (void)cancel;
- (void)pause;

@end
