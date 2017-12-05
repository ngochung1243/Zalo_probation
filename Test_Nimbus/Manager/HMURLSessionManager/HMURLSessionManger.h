//
//  HMURLSessionManger.h
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLUploadTask.h"

@interface HMURLSessionManger : NSObject

- (instancetype _Nullable)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

- (void)cancelAllPendingUploadTask;

- (HMURLUploadTask * _Nonnull)dataTaskWithRequest:(NSURLRequest * _Nonnull)request
                                         progress:(HMUploadProgressBlock _Nullable)progressBlock
                                  completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                     fromFile:(NSURL * _Nonnull)fileURL
                     progress:(HMUploadProgressBlock _Nullable)progressBlock
              completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

- (HMURLUploadTask * _Nonnull)uploadTaskWithRequest:(NSURLRequest * _Nonnull)request
                     fromData:(NSURL * _Nonnull)data
                     progress:(HMUploadProgressBlock _Nullable)progressBlock
              completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

- (HMURLUploadTask * _Nonnull)uploadTaskWithStreamRequest:(NSURLRequest * _Nonnull)request
                           progress:(HMUploadProgressBlock _Nullable)progressBlock
                    completionBlock:(HMUploadCompletionBlock _Nullable)completionBlock;

@end
