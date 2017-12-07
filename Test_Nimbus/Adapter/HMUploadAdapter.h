//
//  HMUploadAdapter.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLSessionManger.h"

@class HMUploadAdapter;

@interface HMUploadAdapter : NSObject

+ (instancetype _Nonnull)shareInstance;

- (BOOL)setMaxConcurrentTaskCount:(NSUInteger)maxCount;
- (NSArray<HMURLUploadTask *> * _Nonnull)getAlreadyTask;

- (void)uploadTaskWithHost:(NSString * _Nonnull)hostString
                  filePath:(NSString * _Nonnull)filePath
                    header:(NSDictionary * _Nullable)header
         completionHandler:(void(^ _Nullable)(HMURLUploadTask * _Nullable uploadTask))handler
                   inQueue:(dispatch_queue_t _Nullable)queue;

- (void)uploadTaskWithHost:(NSString * _Nonnull)hostString
                  filePath:(NSString * _Nonnull)filePath
                    header:(NSDictionary * _Nullable)header
         completionHandler:(void(^ _Nullable)(HMURLUploadTask * _Nullable uploadTask))handler
                  priority:(HMURLUploadTaskPriority)priority
                   inQueue:(dispatch_queue_t _Nullable)queue;

- (void)pauseAllTask;
- (void)cancelAllTask;

@end
