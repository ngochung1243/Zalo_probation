//
//  HMURLUploadTask.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLUploadTask.h"
#import "Constaint.h"

@interface HMURLUploadTask()

@property(strong, nonatomic) NSMutableArray<HMURLUploadProgressBlock> *progressCallbacks;
@property(strong, nonatomic) NSMutableArray<HMURLUploadCompletionBlock> *completionCallbacks;
@property(strong, nonatomic) NSMutableArray<HMURLUploadChangeStateBlock> *changeStateCallbacks;

@property(strong, nonatomic) dispatch_queue_t callbackQueue;

@end

@implementation HMURLUploadTask

- (instancetype)init {
    if (self = [super init]) {
        _totalBytes = 0;
        _sentBytes = 0;
        _currentState = HMURLUploadStateNotRunning;
        _priority = HMURLUploadTaskPriorityMedium;
        
        _progressCallbacks = [NSMutableArray new];
        _completionCallbacks = [NSMutableArray new];
        _changeStateCallbacks = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithTask:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        _task = task;
        _taskIdentifier = task.taskIdentifier;
    }
    
    return self;
}

- (void)resume {
    if (_delegate) {
        [_delegate shouldToResumeHMURLUploadTask:self];
    } else {
        [_task resume];
    }
}

- (void)pause {
    if (_delegate) {
        [_delegate shouldToPauseHMURLUploadTask:self];
    } else {
        [_task suspend];
    }
}

- (void)cancel {
    if (_delegate) {
        [_delegate shouldToCancelHMURLUploadTask:self];
    }
    [_task cancel];
}

- (void)completed {
    if (_totalBytes == 0) {
        _sentBytes = _totalBytes;
    }
    _sentBytes = _totalBytes;
}

- (void)addProgressCallback:(HMURLUploadProgressBlock)progressBlock {
    @synchronized(self) {
        if (progressBlock) {
            [_progressCallbacks addObject:progressBlock];
        }
    }
    
}

- (void)addCompletionCallback:(HMURLUploadCompletionBlock)completionBlock {
    @synchronized(self) {
        if (completionBlock) {
            [_completionCallbacks addObject:completionBlock];
        }
    }
    
}

- (void)addChangeStateCallback:(HMURLUploadChangeStateBlock)changeStateBlock {
    @synchronized(self) {
        if (changeStateBlock) {
            [_changeStateCallbacks addObject:changeStateBlock];
        }
    }
}

- (void)removeProgressCallback:(HMURLUploadProgressBlock)progressBlock {
    @synchronized(self) {
        if ([_progressCallbacks containsObject:progressBlock]) {
            [_progressCallbacks removeObject:progressBlock];
        }
    }
}

- (void)removeCompletionCallback:(HMURLUploadCompletionBlock)completionBlock {
    @synchronized(self) {
        if ([_completionCallbacks containsObject:completionBlock]) {
            [_completionCallbacks removeObject:completionBlock];
        }
    }
}

- (void)removeChangeStateCallback:(HMURLUploadChangeStateBlock)changeStateBlock {
    @synchronized(self) {
        if ([_changeStateCallbacks containsObject:changeStateBlock]) {
            [_changeStateCallbacks removeObject:changeStateBlock];
        }
    }
}

- (NSArray<HMURLUploadProgressBlock> *)getProgressCallbacks {
    @synchronized(self) {
        return [_progressCallbacks copy];
    }
}

- (NSArray<HMURLUploadCompletionBlock> *)getCompletionCallbacks {
    @synchronized(self) {
        return [_completionCallbacks copy];
    }
}

- (NSArray<HMURLUploadChangeStateBlock> *)getChangeStateCallbacks {
    @synchronized(self) {
        return [_changeStateCallbacks copy];
    }
}

- (void)setCallbackQueue:(dispatch_queue_t)callbackQueue {
    @synchronized(self) {
        _callbackQueue = callbackQueue ? callbackQueue : mainQueue;
    }
}

- (dispatch_queue_t)getCallbackQueue {
    return _callbackQueue;
}

- (NSComparisonResult)compare:(HMURLUploadTask *)otherTask {
    if (self.priority < otherTask.priority) {
        return NSOrderedAscending;
    } else if (self.priority > otherTask.priority) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

#pragma mark - Set attributes

- (float)uploadProgress {
    if (_totalBytes == 0) {
        return 0;
    }
    return _sentBytes / _totalBytes;
}



@end
