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

@end

@implementation HMURLUploadTask

- (instancetype)init {
    if (self = [super init]) {
        _totalBytes = 0;
        _sentBytes = 0;
        
        _currentState = HMURLUploadStateNotRunning;
    }
    return self;
}

- (instancetype)initWithTask:(NSURLSessionDataTask *)task {
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
    }
    [_uploadTask cancel];
}

- (void)completed {
    if (_totalBytes == 0) {
        _sentBytes = _totalBytes;
    }
    _sentBytes = _totalBytes;
}

- (float)uploadProgress {
    if (_totalBytes == 0) {
        return 0;
    }
    return _sentBytes / _totalBytes;
}

@end
