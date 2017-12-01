//
//  HMContactQueueEntity.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^HMContactPermissionBlock)(BOOL granted, NSError *error);
typedef void (^HMContactGettingBlock)(NSArray *models, NSError *error);
typedef void (^HMContactSequenceBlock)(NSArray *models);
typedef void (^HMContactSequenceCompleteBlock)(NSError *error);

@interface HMContactQueueEntity: NSObject
@property(strong, nonatomic) dispatch_queue_t queue;

- (instancetype)initWithQueue:(dispatch_queue_t)queue;
@end

@interface HMContactPermissionQueueEntity: HMContactQueueEntity
@property(copy, nonatomic) HMContactPermissionBlock permissionBlock;

- (instancetype)initWithQueue:(dispatch_queue_t)queue permissionBlock:(HMContactPermissionBlock)block;
@end

@interface HMContactGettingQueueEntity: HMContactQueueEntity
@property(copy, nonatomic) HMContactGettingBlock gettingBlock;

- (instancetype)initWithQueue:(dispatch_queue_t)queue gettingBlock:(HMContactGettingBlock)block;
@end

@interface HMContactSequenceQueueEntity: HMContactQueueEntity
@property(copy, nonatomic) HMContactSequenceBlock sequenceBlock;
@property(copy, nonatomic) HMContactSequenceCompleteBlock completeBlock;

- (instancetype)initWithQueue:(dispatch_queue_t)queue sequence:(HMContactSequenceBlock)sequenceBlock complete:(HMContactSequenceCompleteBlock)completeBlock;
@end
