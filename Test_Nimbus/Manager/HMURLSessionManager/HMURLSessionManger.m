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

#define MaxConnection           100000000000000

@interface HMURLSessionManger() <NSURLSessionTaskDelegate, HMURLUploadDelegate>

@property(nonatomic) NSUInteger maxConcurrentUploadTask;

@property(strong, nonatomic) NSURLSession *session;
@property(strong, nonatomic) NSOperationQueue *operationQueue;
@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;
@property(strong, nonatomic) NSMutableArray *pendingUploadTask;
@property(strong, nonatomic) NSMutableArray *runningUploadTask;
@property(strong, nonatomic) dispatch_queue_t processingQueue;
@property(strong, nonatomic) dispatch_queue_t addingUploadQueue;
@property(strong, nonatomic) dispatch_queue_t completionQueue;
@property(strong, nonatomic) HMNetworkManager *networkManager;

@end

@implementation HMURLSessionManger

+ (instancetype)shareInstance {
    static HMURLSessionManger *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] initWithMaxConcurrentTaskCount:3 andConfiguration:nil];
    });
    
    return shareInstance;
}

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount andConfiguration:(NSURLSessionConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        NSUInteger maxUploadTaskCount = MIN(maxCount, MaxConnection);
        configuration.HTTPMaximumConnectionsPerHost = maxUploadTaskCount;

        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_operationQueue];

        _uploadTaskMapping = [NSMutableDictionary new];
        _pendingUploadTask = [NSMutableArray new];
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

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromFile:fileURL];
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask
                                                            progress:progressBlock
                                                     completionBlock:completionBlock];
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)data progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:data];
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask
                                                            progress:progressBlock
                                                     completionBlock:completionBlock];
        return hmUploadTask;
    }
}

- (HMURLUploadTask *)uploadTaskWithStreamRequest:(NSURLRequest *)request progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    @synchronized(self) {
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithStreamedRequest:request];
        HMURLUploadTask *hmUploadTask = [self makeUploadTaskWithTask:uploadTask
                                                            progress:progressBlock
                                                     completionBlock:completionBlock];
        return hmUploadTask;
    }
}

- (NSArray *)getRunningUploadTasks {
    return _runningUploadTask;
}

- (NSArray *)getPendingUploadTasks {
    return _pendingUploadTask;
}

- (void)resumeAllCurrentTask {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask.uploadTask resume];
        }];
    });
}

- (void)suspendAllRunningTask {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.runningUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask.uploadTask suspend];
        }];
    });
}

- (void)cancelAllPendingUploadTask {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(_completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.pendingUploadTask enumerateObjectsUsingBlock:^(HMURLUploadTask *  _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask cancel];
        }];
        [strongSelf.pendingUploadTask removeAllObjects];
    });
}

- (void)invalidateAndCancel {
    [self cancelAllPendingUploadTask];
    [_runningUploadTask removeAllObjects];
    [_session invalidateAndCancel];
}

#pragma mark - Private

- (HMURLUploadTask *)makeUploadTaskWithTask:(NSURLSessionDataTask *)task progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    HMURLUploadTask *hmUploadTask = [[HMURLUploadTask alloc] initWithTask:task];
    hmUploadTask.progressBlock = progressBlock;
    hmUploadTask.completionBlock = completionBlock;
    hmUploadTask.delegate = self;
    if (hmUploadTask) {
        [_uploadTaskMapping setObject:hmUploadTask forKey:@(hmUploadTask.taskIdentifier)];
    }
    return hmUploadTask;
}

- (void)shouldIncreaseCurrentUploadTask {
    if (_pendingUploadTask.count > 0 && (_maxConcurrentUploadTask == -1 || _runningUploadTask.count < _maxConcurrentUploadTask)) {
        HMURLUploadTask *uploadTask = _pendingUploadTask[0];
        [_pendingUploadTask removeObjectAtIndex:0];
        [_runningUploadTask addObject:uploadTask];
        [uploadTask.uploadTask resume];
        uploadTask.currentState = HMURLUploadStateRunning;
        NSLog(@"[HM] Upload Task - Start: %ld", uploadTask.taskIdentifier);
    }
}

- (void)addPendingUploadTask:(HMURLUploadTask *)uploadTask {
    dispatch_async(_completionQueue, ^{
        [_pendingUploadTask addObject:uploadTask];
        [self shouldIncreaseCurrentUploadTask];
    });
}

- (void)cancelPendingUploadTask:(HMURLUploadTask *)uploadTask {
    dispatch_async(_completionQueue, ^{
        [_pendingUploadTask removeObject:uploadTask];
    });
}

- (void)cancelRunningUploadTask:(HMURLUploadTask *)uploadTask {
    dispatch_async(_completionQueue, ^{
        uploadTask.currentState = HMURLUploadStateCancel;
        [uploadTask.uploadTask cancel];
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

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(weakSelf.processingQueue, ^{
        HMURLUploadTask *uploadTask = _uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask) {
            uploadTask.totalBytes = totalBytesExpectedToSend;
            uploadTask.sendedBytes = totalBytesSent;
            if (_delegate) {
                dispatch_async(mainQueue, ^{
                    [_delegate hmURLSessionManager:self didProgressUpdate:uploadTask.uploadProgress ofUploadTask:uploadTask];
                });
            }
            
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(weakSelf.completionQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        HMURLUploadTask *uploadTask = strongSelf.uploadTaskMapping[@(task.taskIdentifier)];
        if (uploadTask) {
            if (uploadTask.currentState != HMURLUploadStateCancel) {
                if (!error) {
                    uploadTask.currentState = HMURLUploadStateCompleted;
                } else {
                    uploadTask.currentState = HMURLUploadStateFailed;
                }
            }

            if (_delegate) {
                dispatch_async(mainQueue, ^{
                    [_delegate hmURLSessionManager:self didCompleteUploadTask:uploadTask withError:error];
                });
            }
            
            [strongSelf.runningUploadTask removeObject:uploadTask];
            [strongSelf shouldIncreaseCurrentUploadTask];
        }
    });
}

#pragma mark - HMURLUploadDelegate

- (void)shouldToResumeHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if ([self checkRunningUploadTask:uploadTask]) {
        [uploadTask.uploadTask resume];
        uploadTask.currentState = HMURLUploadStateRunning;
    } else if (![self checkPendingUploadTask:uploadTask]){
        [self addPendingUploadTask:uploadTask];
    }
}

- (void)shouldToPauseHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if ([self checkRunningUploadTask:uploadTask]) {
        [uploadTask.uploadTask suspend];
        uploadTask.currentState = HMURLUploadStatePaused;
    }
}

- (void)shouldToCancelHMURLUploadTask:(HMURLUploadTask *)uploadTask {
    if ([self checkPendingUploadTask:uploadTask]) {
        [self cancelPendingUploadTask:uploadTask];
    }
    [uploadTask.uploadTask cancel];
    uploadTask.currentState = HMURLUploadStateCancel;
}


@end
