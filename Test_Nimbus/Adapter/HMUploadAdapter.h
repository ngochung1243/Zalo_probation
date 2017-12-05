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

- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didChangeStateUplTaskAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface HMUploadAdapter : NSObject

@property(strong, nonatomic) NSMutableDictionary *uploadSubcription;
@property(strong, nonatomic) NSMutableArray *uploadTasks;
@property(weak, nonatomic) id<HMUploadAdapterDelegate> delegate;

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount;

- (void)uploadNumberOfTask:(NSUInteger)numberTasks
                  progress:(HMUploadProgressBlock)progressBlock
           completionBlock:(HMUploadCompletionBlock)completionBlock;

- (HMURLUploadTask *)createUploadTaskWithProgress:(HMUploadProgressBlock)progressBlock
                                  completionBlock:(HMUploadCompletionBlock)completionBlock;

- (void)subcriptCell:(HMUploadCell *)cell;
- (void)unsubcriptCell:(HMUploadCell *)cell;
@end
