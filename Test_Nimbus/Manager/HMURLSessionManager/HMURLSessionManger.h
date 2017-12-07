//
//  HMURLSessionManger.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLUploadTask.h"
#import "HMPriorityQueue.h"

@class HMURLSessionManger;


/**
 The session manager state protocol
 */
@protocol HMURLSessionManagerDelegate <NSObject>
@optional

- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didBecomeInvalidWithError:(NSError * _Nullable)error;
- (void)didFinishEventsForBackgroundHmURLSessionManager:(HMURLSessionManger * _Nonnull)manager;
- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didCompleteUploadTask:(HMURLUploadTask *)uploadTask withError:error;

@end

@interface HMURLSessionManger : NSObject

@property(weak, nonatomic) id<HMURLSessionManagerDelegate> _Nullable delegate;

- (instancetype _Nullable)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                                           fromFile:(NSURL * _Nonnull)fileURL;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                                           fromData:(NSData * _Nonnull)data;

- (HMURLUploadTask * _Nonnull)uploadTaskWithStreamRequest:(NSURLRequest * _Nonnull)request
                                                 priority:(HMURLUploadTaskPriority)priority
                                                  inQueue:(dispatch_queue_t)queue;

- (NSArray * _Nonnull)getRunningUploadTasks;
- (HMPriorityQueue * _Nonnull)getPendingUploadTasks;

- (void)resumeAllCurrentTask;
- (void)cancelAllPendingUploadTask;
- (void)cancelAllRunningUploadTask;
- (void)suspendAllRunningTask;

- (void)invalidateAndCancel;

@end
