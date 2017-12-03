//
//  HMContactQueueEntity.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactQueueEntity.h"
#import "Constaint.h"

@implementation HMCTEntity

- (instancetype)init
{
    if (self = [super init]) {
        _queue = nil;
    }
    return self;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    if (self = [self init]) {
        _queue = queue ? queue : mainQueue;
    }
    return self;
}

@end

@implementation HMCTPermissionEntity

- (instancetype)init {
    if (self = [super init]) {
        _permissionBlock = nil;
    }
    
    return self;
}


- (instancetype)initWithBlock:(HMCTPermissionBlock)block inQueue:(dispatch_queue_t)queue {
    if (self = [super initWithQueue:queue]) {
        _permissionBlock = block;
    }
    
    return self;
}
@end

@implementation HMCTGettingEntity

- (instancetype)init {
    if (self = [super init]) {
        _gettingBlock = nil;
    }
    
    return self;
}


- (instancetype)initWithBlock:(HMCTGettingBlock)block inQueue:(dispatch_queue_t)queue  {
    if (self = [super initWithQueue:queue]) {
        _gettingBlock = block;
    }
    
    return self;
}
@end

@implementation HMCTGettingSeqEntity

- (instancetype)init {
    if (self = [super init]) {
        _sequenceBlock = nil;
        _completeBlock = nil;
    }
    
    return self;
}

- (instancetype)initWithSequenceBlock:(HMCTGettingSeqBlock)sequenceBlock completionBlock:(HMCTCompletedBlock)completeBlock inQueue:(dispatch_queue_t)queue {
    if (self = [super initWithQueue:queue]) {
        _sequenceBlock = sequenceBlock;
        _completeBlock = completeBlock;
    }
    
    return self;
}

@end
