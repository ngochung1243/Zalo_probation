//
//  HMURLSessionManger.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLUploadTask.h"

@class HMURLSessionManger;


/**
 The session manager state protocol
 */
@protocol HMURLSessionManagerDelegate <NSObject>
@optional

- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didBecomeInvalidWithError:(NSError * _Nullable)error;
- (void)didFinishEventsForBackgroundHmURLSessionManager:(HMURLSessionManger * _Nonnull)manager;

@end

@protocol HMURLSessionTaskDelegate <HMURLSessionManagerDelegate>

- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didProgressUpdate:(float)progress ofUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didCompleteUploadTask:(HMURLUploadTask * _Nonnull)uploadTask withError:(NSError * _Nullable)error;
- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didChangeState:(HMURLUploadState)newState  ofUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;

@end

@interface HMURLSessionManger : NSObject

@property(weak, nonatomic) id<HMURLSessionTaskDelegate> _Nullable delegate;

+ (instancetype _Nullable)shareInstance;

- (instancetype _Nullable)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                                           fromFile:(NSURL * _Nonnull)fileURL progressBlock:(HM)

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                                           fromData:(NSData * _Nonnull)data;

- (HMURLUploadTask * _Nonnull)uploadTaskWithStreamRequest:(NSURLRequest * _Nonnull)request;

- (NSArray * _Nonnull)getRunningUploadTasks;
- (NSArray * _Nonnull)getPendingUploadTasks;

- (void)resumeAllCurrentTask;
- (void)cancelAllPendingUploadTask;
- (void)suspendAllRunningTask;

- (void)invalidateAndCancel;

@end
