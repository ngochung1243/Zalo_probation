//
//  HMContactQueueEntity.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMContactModel.h"

typedef void (^HMCTPermissionBlock)(BOOL granted, NSError *error);
typedef void (^HMCTGettingBlock)(NSArray<HMContactModel *> *models, NSError *error);
typedef void (^HMCTGettingSeqBlock)(NSArray<HMContactModel *> *models);
typedef void (^HMCTCompletedBlock)(NSError *error);

@interface HMCTEntity: NSObject
@property(strong, nonatomic) dispatch_queue_t queue;

- (instancetype)initWithQueue:(dispatch_queue_t)queue;
@end

@interface HMCTPermissionEntity: HMCTEntity
@property(copy, nonatomic) HMCTPermissionBlock permissionBlock;

- (instancetype)initWithBlock:(HMCTPermissionBlock)block inQueue:(dispatch_queue_t)queue;
@end

@interface HMCTGettingEntity: HMCTEntity
@property(copy, nonatomic) HMCTGettingBlock gettingBlock;

- (instancetype)initWithBlock:(HMCTGettingBlock)block inQueue:(dispatch_queue_t)queue;
@end

@interface HMCTGettingSeqEntity: HMCTEntity
@property(copy, nonatomic) HMCTGettingSeqBlock sequenceBlock;
@property(copy, nonatomic) HMCTCompletedBlock completeBlock;

- (instancetype)initWithSequenceBlock:(HMCTGettingSeqBlock)sequenceBlock completionBlock:(HMCTCompletedBlock)completeBlock inQueue:(dispatch_queue_t)queue;
@end
