//
//  HMContactQueueEntity.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactQueueEntity.h"
#import "Constaint.h"

@implementation HMContactQueueEntity

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

@implementation HMContactPermissionQueueEntity

- (instancetype)init {
    if (self = [super init]) {
        _permissionBlock = nil;
    }
    
    return self;
}


- (instancetype)initWithQueue:(dispatch_queue_t)queue permissionBlock:(HMContactPermissionBlock)block {
    if (self = [super initWithQueue:queue]) {
        _permissionBlock = block;
    }
    
    return self;
}
@end

@implementation HMContactGettingQueueEntity

- (instancetype)init {
    if (self = [super init]) {
        _gettingBlock = nil;
    }
    
    return self;
}


- (instancetype)initWithQueue:(dispatch_queue_t)queue gettingBlock:(HMContactGettingBlock)block {
    if (self = [super initWithQueue:queue]) {
        _gettingBlock = block;
    }
    
    return self;
}
@end

@implementation HMContactSequenceQueueEntity

- (instancetype)init {
    if (self = [super init]) {
        _sequenceBlock = nil;
        _completeBlock = nil;
    }
    
    return self;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue sequence:(HMContactSequenceBlock)sequenceBlock complete:(HMContactSequenceCompleteBlock)completeBlock {
    if (self = [super initWithQueue:queue]) {
        _sequenceBlock = sequenceBlock;
        _completeBlock = completeBlock;
    }
    
    return self;
}

@end
