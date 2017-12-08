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
        _operationQueue.maxConcurrentOperationCount = 3;
        
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
                [strongSelf resumeAllCurrentTasks];
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

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL priority:(HMURLUploadTaskPriority)priority {
    if (!request || !fileURL) {
        return nil;
    }
    
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromFile:fileURL];
        if (!uploadTask) {
            return nil;
        }
        
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        if (hmUploadTask) {
            hmUploadTask.priority = priority;
        }
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)data priority:(HMURLUploadTaskPriority)priority {
    if (!request || !data) {
        return nil;
    }
    
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:data];
        if (!uploadTask) {
            return nil;
        }
        
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        if (hmUploadTask) {
            hmUploadTask.priority = priority;
        }
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithStreamRequest:(NSURLRequest *)request priority:(HMURLUploadTaskPriority)priority {
    if (!request) {
        return nil;
    }
    
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithStreamedRequest:request];
        if (!uploadTask) {
            return nil;
        }
        
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask];
        if (hmUploadTask) {
            hmUploadTask.priority = priority;
        }
        return hmUploadTask;
    }
}

- (NSArray *)getRunningUploadTasks {
    @synchronized(self) {
        return [_runningUploadTask copy];
    }
}

- (HMPriorityQueue *)getPendingUploadTasks {
    @synchronized(self) {
        return _pendingUploadTask;
    }
}

- (void)resumeAllCurrentTasks {
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
        for (int i = 0; i < strongSelf.pendingUploadTask.count; i ++) {
            HMURLUploadTask *uploadTask = [strongSelf.pendingUploadTask popObject];
            if (uploadTask) {
                [uploadTask cancel];
            }
        }
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
    if (!task) {
        return nil;
    }
    
    HMURLUploadTask *hmUploadTask = [[HMURLUploadTask alloc] initWithTask:task];
    if (hmUploadTask) {
        hmUploadTask.delegate = self;
        [_uploadTaskMapping setObject:hmUploadTask forKey:@(hmUploadTask.task.taskIdentifier)];
    }
    return hmUploadTask;
}

- (void)shouldIncreaseCurrentUploadTask {
    if (_pendingUploadTask.count > 0 && (_maxConcurrentUploadTask == -1 || _runningUploadTask.count < _maxConcurrentUploadTask)) {
        HMURLUploadTask *uploadTask = [_pendingUploadTask popObject];
        if (uploadTask) {
            [_runningUploadTask addObject:uploadTask];
            [uploadTask.task resume];
            [self changeUploadState:HMURLUploadStateRunning ofUploadTask:uploadTask];
            NSLog(@"[HM] Upload Task - Start: %ld", uploadTask.taskIdentifier);
        }
    }
}

- (void)addPendingUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.pendingUploadTask pushObject:uploadTask];
        [strongSelf changeUploadState:HMURLUploadStatePending ofUploadTask:uploadTask];
        [strongSelf shouldIncreaseCurrentUploadTask];
    });
}

- (void)cancelPendingUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.pendingUploadTask removeObject:uploadTask];
    });
}

- (BOOL)checkPendingUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return NO;
    }
    
    @synchronized(self) {
        if ([_pendingUploadTask containsObject:uploadTask]) {
            return YES;
        }
        return NO;
    }
}

- (BOOL)checkRunningUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return NO;
    }
    
    @synchronized(self) {
        if ([_runningUploadTask containsObject:uploadTask]) {
            return YES;
        }
        return NO;
    }
}

- (void)changeUploadState:(HMURLUploadState)newState ofUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    @synchronized(self) {
        uploadTask.currentState = newState;
        
        NSArray<HMURLUploadCallbackEntry *> *cbEntries = [uploadTask getAllCallbackEntries];
        if (!cbEntries) {
            return;
        }
        
        __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
        [cbEntries enumerateObjectsUsingBlock:^(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.changeStateCallback) {
                dispatch_async(obj.queue, ^{
                    obj.changeStateCallback(weakUploadTask.taskIdentifier, newState);
                });
            }
        }];
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if (!task || bytesSent < 0 || totalBytesSent < 0 || totalBytesExpectedToSend < 0) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_processingQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = strongSelf.uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask && [strongSelf.runningUploadTask containsObject:uploadTask]) {
            uploadTask.totalBytes = totalBytesExpectedToSend;
            uploadTask.sentBytes = totalBytesSent;
            
            NSArray<HMURLUploadCallbackEntry *> *cbEntries = [uploadTask getAllCallbackEntries];
            if (!cbEntries) {
                return;
            }
            
            __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
            [cbEntries enumerateObjectsUsingBlock:^(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.progressCallback) {
                    dispatch_async(obj.queue, ^{
                        obj.progressCallback(weakUploadTask.taskIdentifier, weakUploadTask.uploadProgress);
                    });
                }
            }];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!task) {
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = strongSelf.uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask && [strongSelf.runningUploadTask containsObject:uploadTask]) {
            if (uploadTask.currentState != HMURLUploadStateCancel) {
                if (!error) {
                    uploadTask.totalBytes = task.countOfBytesExpectedToSend;
                    uploadTask.sentBytes = task.countOfBytesSent;
                    [uploadTask completed];
                    [strongSelf changeUploadState:HMURLUploadStateCompleted ofUploadTask:uploadTask];
                } else {
                    [strongSelf changeUploadState:HMURLUploadStateFailed ofUploadTask:uploadTask];
                }
            }
            
            NSArray<HMURLUploadCallbackEntry *> *cbEntries = [uploadTask getAllCallbackEntries];
            if (!cbEntries) {
                return;
            }
            
            __weak __typeof__(uploadTask) weakUploadTask = uploadTask;
            [cbEntries enumerateObjectsUsingBlock:^(HMURLUploadCallbackEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.completionCallback) {
                    dispatch_async(obj.queue, ^{
                        obj.completionCallback(weakUploadTask.taskIdentifier, error);
                    });
                }
            }];
            
            [uploadTask removeAllCallbackEntries];
            strongSelf.uploadTaskMapping[@(uploadTask.task.taskIdentifier)] = nil;
            
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
    if (!uploadTask) {
        return;
    }
    
    if ([self checkRunningUploadTask:uploadTask]) {
        [uploadTask.task resume];
        [self changeUploadState:HMURLUploadStateRunning ofUploadTask:uploadTask];
    } else if (![self checkPendingUploadTask:uploadTask]){
        [self addPendingUploadTask:uploadTask];
    }
}

- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    if ([self checkRunningUploadTask:uploadTask]) {
        [uploadTask.task suspend];
        [self changeUploadState:HMURLUploadStatePaused ofUploadTask:uploadTask];
    }
}

- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if (!uploadTask) {
        return;
    }
    
    if ([self checkPendingUploadTask:uploadTask]) {
        [self cancelPendingUploadTask:uploadTask];
    }
    [uploadTask.task cancel];
    [self changeUploadState:HMURLUploadStateCancel ofUploadTask:uploadTask];
}


@end
