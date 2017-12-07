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

@property(weak, nonatomic) NSURLSessionDataTask * _Nullable uploadTask;
@property(weak, nonatomic) id<HMURLUploadDelegate> _Nullable delegate;
@property(nonatomic) HMURLUploadState currentState;

- (instancetype _Nullable)initWithTask:(NSURLSessionDataTask * _Nonnull)task;

- (void)resume;
- (void)cancel;
- (void)pause;
- (void)completed;

@end
