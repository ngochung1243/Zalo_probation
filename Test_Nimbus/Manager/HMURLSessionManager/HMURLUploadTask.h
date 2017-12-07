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
    HMURLUploadStateNotRunning = 0,
    HMURLUploadStateRunning,
    HMURLUploadStatePending,
    HMURLUploadStatePaused,
    HMURLUploadStateCancel,
    HMURLUploadStateCompleted,
    HMURLUploadStateFailed
};

typedef NS_ENUM(NSInteger, HMURLUploadTaskPriority) {
    HMURLUploadTaskPriorityLow = 0,
    HMURLUploadTaskPriorityMedium,
    HMURLUploadTaskPriorityHigh
};

typedef void(^HMURLUploadProgressBlock) (HMURLUploadTask * _Nonnull uploadTask, float progress);
typedef void(^HMURLUploadCompletionBlock) (HMURLUploadTask * _Nonnull uploadTask, NSError * _Nullable error);
typedef void(^HMURLUploadChangeStateBlock) (HMURLUploadTask * _Nonnull uploadTask, HMURLUploadState newState);

@protocol HMURLUploadDelegate <NSObject>

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;

@end

@interface HMURLUploadTask : NSObject

@property(nonatomic) NSUInteger taskIdentifier;
@property(nonatomic) float totalBytes;
@property(nonatomic) float sentBytes;
@property(nonatomic, readonly) float uploadProgress;

@property(weak, nonatomic) NSURLSessionDataTask * _Nullable task;
@property(weak, nonatomic) id<HMURLUploadDelegate> _Nullable delegate;
@property(nonatomic) HMURLUploadState currentState;
@property(nonatomic) HMURLUploadTaskPriority priority;
@property(strong, nonatomic) NSString * _Nonnull host;
@property(strong, nonatomic) NSString * _Nonnull filePath;

- (instancetype _Nullable)initWithTask:(NSURLSessionDataTask * _Nonnull)task;

- (void)resume;
- (void)cancel;
- (void)pause;
- (void)completed;

- (void)addProgressCallback:(HMURLUploadProgressBlock _Nonnull)progressBlock;
- (void)addCompletionCallback:(HMURLUploadCompletionBlock _Nonnull)completionBlock;
- (void)addChangeStateCallback:(HMURLUploadChangeStateBlock _Nonnull)changeStateBlock;

- (void)removeProgressCallback:(HMURLUploadProgressBlock _Nonnull)progressBlock;
- (void)removeCompletionCallback:(HMURLUploadCompletionBlock _Nonnull)completionBlock;
- (void)removeChangeStateCallback:(HMURLUploadChangeStateBlock _Nonnull)changeStateBlock;

- (NSArray<HMURLUploadProgressBlock> * _Nonnull)getProgressCallbacks;
- (NSArray<HMURLUploadCompletionBlock> * _Nonnull)getCompletionCallbacks;
- (NSArray<HMURLUploadChangeStateBlock> * _Nonnull)getChangeStateCallbacks;

- (void)setCallbackQueue:(dispatch_queue_t _Nullable)callbackQueue;
- (dispatch_queue_t _Nonnull)getCallbackQueue;

- (NSComparisonResult)compare:(HMURLUploadTask * _Nonnull)otherTask;

@end
