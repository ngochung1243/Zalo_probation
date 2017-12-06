//
//  HMURLUploadTask.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HMURLUploadTask;

typedef NS_ENUM(NSInteger, HMURLUploadState) {
    HMURLUploadStateNotRunning,
    HMURLUploadStateRunning,
    HMURLUploadStatePaused,
    HMURLUploadStateCancel,
    HMURLUploadStateCompleted,
    HMURLUploadStateFailed
};

typedef void (^HMUploadProgressBlock)(NSUInteger taskIdentifier, float progress);
typedef void (^HMUploadCompletionBlock)(NSUInteger taskIdentifier, NSURLResponse * _Nonnull reponse, NSError * _Nullable error);

typedef void (^HMUploadChangeStateBlock)(HMURLUploadTask * _Nullable uploadTask);


@protocol HMURLUploadDelegate <NSObject>

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;

@end

@interface HMURLUploadTask : NSObject

@property(nonatomic) NSUInteger taskIdentifier;
@property(nonatomic) float totalBytes;
@property(nonatomic) float sendedBytes;
@property(nonatomic) float uploadProgress;

@property(weak, nonatomic) NSURLSessionDataTask * _Nullable uploadTask;
@property(strong, nonatomic) HMUploadProgressBlock _Nullable progressBlock;
@property(strong, nonatomic) HMUploadCompletionBlock _Nullable completionBlock;
@property(weak, nonatomic) id<HMURLUploadDelegate> _Nullable delegate;
@property(nonatomic) HMURLUploadState currentState;
@property(strong, nonatomic) HMUploadChangeStateBlock _Nullable changeStateBlock;

- (instancetype _Nullable)initWithTask:(NSURLSessionDataTask * _Nonnull)task;

- (void)resume;
- (void)cancel;
- (void)pause;

@end
