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

@protocol HMURLSessionManagerDelegate <NSObject>

- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didProgressUpdate:(float)progress ofUploadTask:(HMURLUploadTask * _Nonnull)uploadTask;
- (void)hmURLSessionManager:(HMURLSessionManger * _Nonnull)manager didCompleteUploadTask:(HMURLUploadTask * _Nonnull)uploadTask withError:(NSError * _Nullable)error;

@end

@interface HMURLSessionManger : NSObject

@property(weak, nonatomic) id<HMURLSessionManagerDelegate> _Nullable delegate;

+ (instancetype _Nullable)shareInstance;

- (instancetype _Nullable)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                     fromFile:(NSURL * _Nonnull)fileURL
                     progress:(HMUploadProgressBlock _Nullable)progressBlock
              completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                     fromData:(NSData * _Nonnull)data
                     progress:(HMUploadProgressBlock _Nullable)progressBlock
              completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

- (HMURLUploadTask * _Nonnull)uploadTaskWithStreamRequest:(NSURLRequest * _Nonnull)request
                           progress:(HMUploadProgressBlock _Nullable)progressBlock
                    completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

- (NSArray * _Nonnull)getRunningUploadTasks;
- (NSArray * _Nonnull)getPendingUploadTasks;

- (void)resumeAllCurrentTask;
- (void)cancelAllPendingUploadTask;
- (void)suspendAllRunningTask;

- (void)invalidateAndCancel;

@end
