//
//  HMUploadAdapter.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMURLSessionManger.h"
#import "HMUploadCell.h"

@class HMUploadAdapter;

@protocol HMUploadAdapterDelegate <NSObject>

- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didChangeStateUplTask:(HMURLUploadTask *)uploadTask;
- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didProgressUpdate:(float)progress ofUploadTask:(HMURLUploadTask *)uploadTask;
- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didCompleteUploadTask:(HMURLUploadTask *)uploadTask withError:(NSError *)error;

@end

@interface HMUploadAdapter : NSObject

@property(strong, nonatomic) NSMutableDictionary *uploadSubcription;
@property(strong, nonatomic) NSMutableArray<HMURLUploadTask *> *uploadTasks;
@property(weak, nonatomic) id<HMUploadAdapterDelegate> delegate;

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount;

- (void)uploadNumberOfTask:(NSUInteger)numberTasks
      progressBlockPerTask:(HMUploadProgressBlock)progressBlock
    completionBlockPerTask:(HMUploadCompletionBlock)completionBlock
         completionHandler:(void(^)(void))handler;

- (HMURLUploadTask *)createUploadTaskWithProgress:(HMUploadProgressBlock)progressBlock
                                  completionBlock:(HMUploadCompletionBlock)completionBlock;

- (void)subcriptTaskId:(NSUInteger)taskId withIndexPath:(NSIndexPath *)indexPath;
- (void)unsubcriptTaskId:(NSUInteger)taskId;
@end
