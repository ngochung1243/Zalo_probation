//
//  HMUploadAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadAdapter.h"
#import "Constaint.h"

@interface HMUploadAdapter() <HMURLSessionManagerDelegate>

@property(strong, nonatomic) NSMutableDictionary *uploadTaskMapping;

@property(strong, nonatomic) HMURLSessionManger *sessionManager;
@property(strong, nonatomic) dispatch_queue_t serialQueue;

@property(nonatomic) NSUInteger maxCount;

@end

@implementation HMUploadAdapter

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (instancetype)shareInstance {
    static HMUploadAdapter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithMaxConcurrentTaskCount:3];
    });
    
    return instance;
}

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount {
    if (self = [super init]) {
        _uploadTaskMapping = [NSMutableDictionary new];
        
        _maxCount = maxCount;
        _sessionManager = [[HMURLSessionManger alloc] initWithMaxConcurrentTaskCount:maxCount andConfiguration:nil];
        _sessionManager.delegate = self;
        
        _serialQueue = dispatch_queue_create("com.hungmai.HMUploadAdater.serialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    NSLog(@"[HM] HMUploadAdapter - dealloc");
}

#pragma mark - Public

- (BOOL)setMaxConcurrentTaskCount:(NSUInteger)maxCount {
    if (maxCount == NSNotFound) {
        return NO;
    }
    
    @synchronized(self) {
        if (_uploadTaskMapping.count > 0) {
            NSLog(@"[HM] HMUploadAdapter - Can't set max concurrent task count because still having upload tasks running or pending");
            return NO;
        }
        
        _maxCount = maxCount;
        [_sessionManager invalidateAndCancel]; //Invalidate the session. It will re-init at 'URLsession:didBecomeInvalidWithError:' callback
        return YES;
    }
}

- (NSUInteger)getMaxConcurrentTaskCount {
    return _maxCount;
}

- (NSArray<HMURLUploadTask *> *)getAlreadyTask {
    @synchronized(self) {
        NSArray *array = [_uploadTaskMapping allValues];
        if (!array) {
            return nil;
        }
        
        return array;
    }
}

- (void)uploadTaskWithHost:(NSString *)hostString
                  filePath:(NSString *)filePath
                    header:(NSDictionary *)header
         completionHandler:(void(^)(HMURLUploadTask *))handler
                   inQueue:(dispatch_queue_t)queue {
    
    [self uploadTaskWithHost:hostString
                    filePath:filePath
                      header:header
           completionHandler:handler
                    priority:HMURLUploadTaskPriorityMedium
                     inQueue:queue];
}

- (void)uploadTaskWithHost:(NSString * _Nonnull)hostString
                  filePath:(NSString * _Nonnull)filePath
                    header:(NSDictionary * _Nullable)header
         completionHandler:(void(^ _Nullable)(HMURLUploadTask * _Nullable uploadTask))handler
                  priority:(HMURLUploadTaskPriority)priority
                   inQueue:(dispatch_queue_t _Nullable)queue {
    
    if (!hostString || !filePath) {
        if (handler) {
            [self dispatchAsyncWithQueue:queue block:^{
                handler(nil);
            }];
        }
    }
    
    //Get and check another task has same host & file path and return it if existed for the multiple-request purpose
    HMURLUploadTask *similarTask = [self getSimilarTaskWithHost:hostString filePath:filePath];
    if (similarTask) {
        if (handler) {
            [self dispatchAsyncWithQueue:queue block:^{
                handler(similarTask);
            }];
        }
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        NSURLRequest *request = [self makeRequestWithHost:hostString filePath:filePath header:header];
        if (!request) {
            if (handler) {
                [self dispatchAsyncWithQueue:queue block:^{
                    handler(nil);
                }];
            }
            return;
        }
        HMURLUploadTask *uploadTask = [_sessionManager uploadTaskWithStreamRequest:request priority:priority];
        if (uploadTask) {
            uploadTask.host = hostString;
            uploadTask.filePath = filePath;
            
            //Add one more callback for the upload task to remove the task from 'uploadTaskMapping' when this task is completed or canceled
            __weak __typeof__(self) weakSelf = self;
            [uploadTask addCallbacksWithProgressCB:nil
                                      completionCB:^(NSUInteger taskIdentifier, NSError * _Nullable error) {
                                          __typeof__(self) strongSelf = weakSelf;
                                          strongSelf.uploadTaskMapping[@(taskIdentifier)] = nil;
                                          
                                      } changeStateCB:^(NSUInteger taskIdentifier, HMURLUploadState newState) {
                                          __typeof__(self) strongSelf = weakSelf;
                                          strongSelf.uploadTaskMapping[@(taskIdentifier)] = nil;
                                      } inQueue:_serialQueue];
            
            NSUInteger hashHost = [self hashRequestWithHostString:hostString filePath:filePath]; //Hash the host link & file path to generate identifier for the task
            if (hashHost != NSNotFound) {
                uploadTask.taskIdentifier = hashHost;
                [_uploadTaskMapping setObject:uploadTask forKey:@(hashHost)];
            }
        }

        if (handler) {
            [self dispatchAsyncWithQueue:queue block:^{
                handler(uploadTask);
            }];
        }
    });
}

- (void)pauseAllTask {
    [_sessionManager suspendAllRunningTask];
}

- (void)cancelAllTask {
    if (_uploadTaskMapping.count == 0) {
        return;
    }
    
    [self dispatchAsyncWithQueue:_serialQueue block:^{
        [_sessionManager cancelAllRunningUploadTask];
        [_sessionManager cancelAllPendingUploadTask];
        
        [_uploadTaskMapping removeAllObjects];
    }];
}

#pragma mark - Private

- (NSDictionary *)getDefaultHeader {
    return @{@"content-type": @"multipart/form-data"};
}

- (NSURLRequest *)makeRequestWithHost:(NSString *)hostString filePath:(NSString *)filePath header:(NSDictionary *)header {
    if (!hostString || !filePath) {
        return nil;
    }
    
    NSDictionary *targetHeader = header ? header : [self getDefaultHeader];
    
    NSArray *parameters = @[ @{ @"name": @"file", @"fileName": filePath } ];
    NSString *boundary = @"----WebKitFormBoundary7MA4YWxkTrZu0gW";
    
    NSError *error;
    NSMutableString *body = [NSMutableString string];
    for (NSDictionary *param in parameters) {
        [body appendFormat:@"--%@\r\n", boundary];
        if (param[@"fileName"]) {
            [body appendFormat:@"Content-Disposition:form-data; name=\"%@\"; filename=\"%@\"\r\n", param[@"name"], param[@"fileName"]];
            [body appendFormat:@"Content-Type: %@\r\n\r\n", param[@"contentType"]];
            [body appendFormat:@"%@", [NSString stringWithContentsOfFile:param[@"fileName"] encoding:NSASCIIStringEncoding error:&error]];
            if (error) {
                NSLog(@"%@", error);
            }
        } else {
            [body appendFormat:@"Content-Disposition:form-data; name=\"%@\"\r\n\r\n", param[@"name"]];
            [body appendFormat:@"%@", param[@"value"]];
        }
    }
    [body appendFormat:@"\r\n--%@--\r\n", boundary];
    NSData *postData = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:hostString]];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:targetHeader];
    [request setHTTPBody:postData];
    return request;
}

- (NSUInteger)hashRequestWithHostString:(NSString *)hostString filePath:(NSString *)filePath {
    if (!hostString || !filePath) {
        return NSNotFound;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"%@-%@", hostString, filePath];
    return [requestString hash];
}

- (HMURLUploadTask *)getSimilarTaskWithHost:(NSString *)hostString filePath:(NSString *)filePath {
    if (!hostString || !filePath) {
        return nil;
    }
    
    NSInteger taskId = [self hashRequestWithHostString:hostString filePath:filePath];
    HMURLUploadTask *similarTask = [_uploadTaskMapping objectForKey:@(taskId)];
    return similarTask;
}

- (dispatch_queue_t)getValidQueueWithQueue:(dispatch_queue_t)queue {
    return queue ? queue : mainQueue;
}

- (void)dispatchAsyncWithQueue:queue block:(void(^)(void))block {
    dispatch_queue_t validQueue = [self getValidQueueWithQueue:queue];
    dispatch_async(validQueue, block);
}

- (void)hmURLSessionManager:(HMURLSessionManger *)manager didBecomeInvalidWithError:(NSError *)error {
    __weak __typeof__(self) weakSelf = self;
    [self dispatchAsyncWithQueue:_serialQueue block:^{
        __typeof__(self) strongSelf = weakSelf;
        NSLog(@"[HM] HMUploadAdapter - Re-init session manager");
        strongSelf.sessionManager = [[HMURLSessionManger alloc] initWithMaxConcurrentTaskCount:strongSelf.maxCount andConfiguration:nil];
        strongSelf.sessionManager.delegate = strongSelf;
    }];
}

@end
