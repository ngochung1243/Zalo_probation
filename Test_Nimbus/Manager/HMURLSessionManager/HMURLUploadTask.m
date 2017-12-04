//
//  HMURLUploadTask.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLUploadTask.h"

@implementation HMURLUploadTask

- (instancetype)init {
    if (self = [super init]) {
        _uploadProgress = 0;
        _progressBlock = nil;
        _completionBlock = nil;
    }
    return self;
}

- (instancetype)initWithUploadTask:(NSURLSessionUploadTask *)task {
    if (self = [self init]) {
        _uploadTask = task;
        _taskIdentifier = task.taskIdentifier;
    }
    
    return self;
}

- (void)resume {
    if (_delegate) {
        [_delegate shouldToResumeHMURLUploadTask:self];
    } else {
        [_uploadTask resume];
    }
}

- (void)pause {
    if (_delegate) {
        [_delegate shouldToPauseHMURLUploadTask:self];
    } else {
        [_uploadTask suspend];
    }
}

- (void)cancel {
    if (_delegate) {
        [_delegate shouldToCancelHMURLUploadTask:self];
    } else {
        [_uploadTask cancel];
    }
}

@end
