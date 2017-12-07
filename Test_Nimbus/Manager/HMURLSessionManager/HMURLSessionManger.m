//
//  HMURLSessionManger.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMURLSessionManger.h"
#import "HMNetworkManager.h"
#import "Constaint.h"

#define MaxConnection           100

@interface HMURLSessionManger() <NSURLSessionTaskDelegate, HMURLUploadDelegate>

@property(nonatomic) NSUInteger maxConcurrentUploadTask;

@property(strong, nonatomic) NSURLSession *session;
@property(strong, nonatomic) NSOperationQueue *operationQueue;
@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;
@property(strong, nonatomic) HMPriorityQueue<HMURLUploadTask *> *pendingUploadTask;
@property(strong, nonatomic) NSMutableArray *runningUploadTask;
@property(strong, nonatomic) dispatch_queue_t processingQueue;
@property(strong, nonatomic) dispatch_queue_t completionQueue;
@property(strong, nonatomic) HMNetworkManager *networkManager;

@end

@implementation HMURLSessionManger

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.hungmai.HMURLSessionManager.bgConfiguration"];
        }
        NSUInteger maxUploadTaskCount = MIN(maxCount, MaxConnection);
        configuration.HTTPMaximumConnectionsPerHost = maxUploadTaskCount;

        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_operationQueue];

        _uploadTaskMapping = [NSMutableDictionary new];
        _pendingUploadTask = [HMPriorityQueue new];
        _runningUploadTask = [NSMutableArray new];
        _maxConcurrentUploadTask = maxUploadTaskCount;
        
        _networkManager = [HMNetworkManager shareInstance];
        
        __weak __typeof__(self) weakSelf = self;
        _networkManager.networkStatusChangeBlock = ^(HMNetworkStatus status) {
            __typeof__(self) strongSelf = weakSelf;
            if (strongSelf.networkManager.isReachable) {
                [strongSelf resumeAllCurrentTask];
            } else {
                [strongSelf suspendAllRunningTask];
            }
        };
        
        _processingQueue = dispatch_queue_create("com.hungmai.HMURLSessionManager.processingQueue", DISPATCH_QUEUE_CONCURRENT);
        _completionQueue = dispatch_queue_create("com.hungmai.HMURLSessionManager.completionQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"[HM] HMURLSessionManager - dealloc");
}

#pragma mark - Public

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromFile:fileURL];
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)data {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:data];
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithStreamRequest:(NSURLRequest *)request priority:(HMURLUploadTaskPriority)priority inQueue:(dispatch_queue_t)queue {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithStreamedRequest:request];
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        hmUploadTask.priority = priority;
        [hmUploadTask setCallbackQueue:queue];
        return hmUploadTask;
    }
}

- (NSArray *)getRunningUploadTasks {
    return _runningUploadTask;
}

- (HMPriorityQueue *)getPendingUploadTasks {
    return _pendingUploadTask;
}

- (void)resumeAllCurrentTask {
    if (_runningUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask.task resume];
        }];
    });
}

- (void)suspendAllRunningTask {
    if (_runningUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask.task suspend];
        }];
    });
}

- (void)cancelAllPendingUploadTask {
    if (_pendingUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = [strongSelf.pendingUploadTask popObject];
        [uploadTask cancel];
    });
}

- (void)cancelAllRunningUploadTask {
    if (_runningUploadTask.count == 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask cancel];
        }];
        [strongSelf.runningUploadTask removeAllObjects];
    });
}

- (void)invalidateAndCancel {
    [self cancelAllPendingUploadTask];
    [_runningUploadTask removeAllObjects];
    [_session invalidateAndCancel];
}

#pragma mark - Private

- (HMURLUploadTask *)makeUploadTaskWithTask:(NSURLSessionDataTask *)task {
    HMURLUploadTask *hmUploadTask = [[HMURLUploadTask alloc] initWithTask:task];
    hmUploadTask.delegate = self;
    if (hmUploadTask) {
        [_uploadTaskMapping setObject:hmUploadTask forKey:@(hmUploadTask.taskIdentifier)];
    }
    return hmUploadTask;
}

- (void)shouldIncreaseCurrentUploadTask {
    if (_pendingUploadTask.count > 0 && (_maxConcurrentUploadTask == -1 || _runningUploadTask.count < _maxConcurrentUploadTask)) {
        HMURLUploadTask *uploadTask = [_pendingUploadTask popObject];
        [_runningUploadTask addObject:uploadTask];
        [uploadTask.task resume];
        [self changeUploadState:HMURLUploadStateRunning ofUploadTask:uploadTask];
        NSLog(@"[HM] Upload Task - Start: %ld", uploadTask.taskIdentifier);
    }
}

- (void)addPendingUploadTask:(HMURLUploadTask *)uploadTask {
    dispatch_async(_completionQueue, ^{
        [_pendingUploadTask pushObject:uploadTask];
        [self changeUploadState:HMURLUploadStatePending ofUploadTask:uploadTask];
        [self shouldIncreaseCurrentUploadTask];
    });
}

- (void)cancelPendingUploadTask:(HMURLUploadTask *)uploadTask {
    dispatch_async(_completionQueue, ^{
        [_pendingUploadTask removeObject:uploadTask];
    });
}

- (BOOL)checkPendingUploadTask:(HMURLUploadTask *)uploadTask {
    @synchronized(self) {
        if ([_pendingUploadTask containsObject:uploadTask]) {
            return YES;
        }
        return NO;
    }
}

- (BOOL)checkRunningUploadTask:(HMURLUploadTask *)uploadTask {
    @synchronized(self) {
        if ([_runningUploadTask containsObject:uploadTask]) {
            return YES;
        }
        return NO;
    }
}

- (void)changeUploadState:(HMURLUploadState)newState ofUploadTask:(HMURLUploadTask *)uploadTask {
    uploadTask.currentState = newState;
    
    NSArray<HMURLUploadChangeStateBlock> *changeStateCallbacks = [uploadTask getChangeStateCallbacks];
    __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
    dispatch_async([weakUploadTask getCallbackQueue], ^{
        [changeStateCallbacks enumerateObjectsUsingBlock:^(HMURLUploadChangeStateBlock  _Nonnull changeStateBlock, NSUInteger idx, BOOL * _Nonnull stop) {
            changeStateBlock(weakUploadTask, newState);
        }];
    });
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(weakSelf.processingQueue, ^{
        HMURLUploadTask *uploadTask = _uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask && [_runningUploadTask containsObject:uploadTask]) {
            uploadTask.totalBytes = totalBytesExpectedToSend;
            uploadTask.sentBytes = totalBytesSent;
            NSArray<HMURLUploadProgressBlock> *progressCallbacks = [uploadTask getProgressCallbacks];
            __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
            dispatch_async([weakUploadTask getCallbackQueue], ^{
                [progressCallbacks enumerateObjectsUsingBlock:^(HMURLUploadProgressBlock  _Nonnull progressBlock, NSUInteger idx, BOOL * _Nonnull stop) {
                    progressBlock(weakUploadTask, weakUploadTask.uploadProgress);
                }];
            });
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(weakSelf.completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = strongSelf.uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask && [_runningUploadTask containsObject:uploadTask]) {
            if (uploadTask.currentState != HMURLUploadStateCancel) {
                if (!error) {
                    uploadTask.totalBytes = task.countOfBytesExpectedToSend;
                    uploadTask.sentBytes = task.countOfBytesSent;
                    [uploadTask completed];
                    [self changeUploadState:HMURLUploadStateCompleted ofUploadTask:uploadTask];
                } else {
                    [self changeUploadState:HMURLUploadStateFailed ofUploadTask:uploadTask];
                }
            }

            NSArray<HMURLUploadCompletionBlock> *completionCallbacks = [uploadTask getCompletionCallbacks];
            __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
            dispatch_async([weakUploadTask getCallbackQueue], ^{
                [completionCallbacks enumerateObjectsUsingBlock:^(HMURLUploadCompletionBlock  _Nonnull completionBlock, NSUInteger idx, BOOL * _Nonnull stop) {
                    completionBlock(weakUploadTask, error);
                }];
            });
            
            if (_delegate && [_delegate respondsToSelector:@selector(hmURLSessionManager:didCompleteUploadTask:withError:)]) {
                dispatch_async(mainQueue, ^{
                    [_delegate hmURLSessionManager:self didCompleteUploadTask:uploadTask withError:error];
                });
            }
            
            [strongSelf.runningUploadTask removeObject:uploadTask];
            [strongSelf shouldIncreaseCurrentUploadTask];
        }
    });
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"[HM] HMURLSessionManager - Finished background task");
    if (_delegate && [_delegate respondsToSelector:@selector(didFinishEventsForBackgroundHmURLSessionManager:)]) {
        [_delegate didFinishEventsForBackgroundHmURLSessionManager:self];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"[HM] HMURLSessionManager - Invalid error: %@", error);
    [self cancelAllRunningUploadTask];
    [self cancelAllPendingUploadTask];
    if (_delegate && [_delegate respondsToSelector:@selector(hmURLSessionManager:didBecomeInvalidWithError:)]) {
        [_delegate hmURLSessionManager:self didBecomeInvalidWithError:error];
    }
}

#pragma mark - HMURLUploadDelegate

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if ([self checkRunningUploadTask:uploadTask]) {
        [uploadTask.task resume];
        [self changeUploadState:HMURLUploadStateRunning ofUploadTask:uploadTask];
    } else if (![self checkPendingUploadTask:uploadTask]){
        [self addPendingUploadTask:uploadTask];
    }
}

- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if ([self checkRunningUploadTask:uploadTask]) {
        [uploadTask.task suspend];
        [self changeUploadState:HMURLUploadStatePaused ofUploadTask:uploadTask];
    }
}

- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if ([self checkPendingUploadTask:uploadTask]) {
        [self cancelPendingUploadTask:uploadTask];
    }
    [uploadTask.task cancel];
    [self changeUploadState:HMURLUploadStateCancel ofUploadTask:uploadTask];
}


@end
