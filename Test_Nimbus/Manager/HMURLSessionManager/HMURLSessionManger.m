//
//  HMURLSessionManger.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLSessionManger.h"
#import "Constaint.h"

@interface HMURLSessionManger() <NSURLSessionTaskDelegate, HMURLUploadDelegate>

@property(nonatomic) int maxConcurrentUploadTask;
@property(nonatomic) int currentRunningUploadTask;

@property(strong, nonatomic) NSURLSession *session;
@property(strong, nonatomic) NSOperationQueue *operationQueue;
@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;
@property(strong, nonatomic) NSMutableArray *pendingUploadTask;
@property(strong, nonatomic) dispatch_queue_t processingQueue;
@property(strong, nonatomic) dispatch_queue_t addingUploadQueue;
@property(strong, nonatomic) dispatch_queue_t completionQueue;
@property(strong, nonatomic) dispatch_group_t completionGroup;

@end

@implementation HMURLSessionManger

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 10;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_operationQueue];
        
        _uploadTaskMapping = [NSMutableDictionary new];
        _pendingUploadTask = [NSMutableArray new];
        _maxConcurrentUploadTask = 3;
        _currentRunningUploadTask = 0;
        
        _processingQueue = dispatch_queue_create("com.hungmai.HMURLSessionManager.processingQueue", DISPATCH_QUEUE_CONCURRENT);
        _completionQueue = dispatch_queue_create("com.hungmai.HMURLSessionManager.completionQueue", DISPATCH_QUEUE_SERIAL);
        _completionGroup = dispatch_group_create();
    }
    
    return self;
}

- (void)setMaximumConcurrentUpload:(int)maxCount {
    _maxConcurrentUploadTask = maxCount;
}

- (void)cancelAllPendingUploadTask {
    
}

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromFile:fileURL];
        HMURLUploadTask *hmUploadTask = [[HMURLUploadTask alloc] initWithUploadTask:uploadTask];
        hmUploadTask.progressBlock = progressBlock;
        hmUploadTask.completionBlock = completionBlock;
        hmUploadTask.delegate = self;
        if (hmUploadTask) {
            [_uploadTaskMapping setObject:hmUploadTask forKey:@(hmUploadTask.taskIdentifier)];
        }
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSURL *)data progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    return nil;
}

- (HMURLUploadTask *)uploadTaskWithStreamRequest:(NSURLRequest *)request progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    return nil;
}

#pragma mark - Private

- (void)shouldIncreaseCurrentUploadTask {
    if (_pendingUploadTask.count > 0 && _currentRunningUploadTask < _maxConcurrentUploadTask) {
        _currentRunningUploadTask += 1;
        HMURLUploadTask *uploadTask = _pendingUploadTask[0];
        [_pendingUploadTask removeObjectAtIndex:0];
        [uploadTask.uploadTask resume];
    }
}

- (void)addPendingUploadTask:(HMURLUploadTask *)uploadTask {
    dispatch_async(_completionQueue, ^{
        [_pendingUploadTask addObject:uploadTask];
        [self shouldIncreaseCurrentUploadTask];
    });
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    dispatch_async(_processingQueue, ^{
        HMURLUploadTask *uploadTask = _uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask) {
            float uploadProgress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
            uploadTask.uploadProgress = uploadProgress;
            dispatch_async(mainQueue, ^{
                if (uploadTask.progressBlock) {
                    uploadTask.progressBlock(uploadTask.uploadProgress);
                }
            });
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(_completionQueue, ^{
        HMURLUploadTask *uploadTask = _uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask) {
            dispatch_async(mainQueue, ^{
                if (uploadTask.completionBlock) {
                    uploadTask.completionBlock(task.response, error);
                }
            });
        }
        _currentRunningUploadTask -= 1;
        [self shouldIncreaseCurrentUploadTask];
    });
}

#pragma mark - HMURLUploadDelegate

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    [self addPendingUploadTask:uploadTask];
}

- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    
}

- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    
}


@end
