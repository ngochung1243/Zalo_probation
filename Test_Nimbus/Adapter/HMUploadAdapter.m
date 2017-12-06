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

@property(strong, nonatomic) HMURLSessionManger *sessionManager;
@property(strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation HMUploadAdapter

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount {
    if (self = [super init]) {
        _uploadTasks = [NSMutableArray new];
        _uploadSubcription = [NSMutableDictionary new];
//        _sessionManager = [[HMURLSessionManger alloc] initWithMaxConcurrentTaskCount:maxCount andConfiguration:nil];
        _sessionManager = [HMURLSessionManger shareInstance];
        _sessionManager.delegate = self;
        
        _serialQueue = dispatch_queue_create("com.hungmai.HMUploadAdater.serialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    NSLog(@"[HM] HMUploadAdapter - dealloc");
    [_sessionManager invalidateAndCancel];
}

- (void)getAlreadyRunningTask {
    _uploadTasks = [[_sessionManager getRunningUploadTasks] mutableCopy];
}

- (void)uploadNumberOfTask:(NSUInteger)numberTasks
      progressBlockPerTask:(HMUploadProgressBlock)progressBlock
    completionBlockPerTask:(HMUploadCompletionBlock)completionBlock
         completionHandler:(void(^)(void))handler {
    dispatch_async(_serialQueue, ^{
        for (int i = 0; i < numberTasks; i ++) {
            HMURLUploadTask *uploadTask = [self createUploadTaskWithProgress:progressBlock completionBlock:completionBlock];
            if (uploadTask) {
                [_uploadTasks addObject:uploadTask];
            }
            [uploadTask resume];
        }
        
        if (handler) {
            dispatch_async(mainQueue, ^{
                handler();
            });
        }
    });
}

- (HMURLUploadTask *)createUploadTaskWithProgress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    NSDictionary *headers = @{ @"content-type": @"multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW",
                               @"cache-control": @"no-cache",
                               @"postman-token": @"4b78a659-7aea-6641-2121-64e6d630bda1" };
    
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"GoTiengViet" withExtension:@"dmg"];
    NSArray *parameters = @[ @{ @"name": @"file", @"fileName": [fileUrl path] } ];
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
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"]];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];
    
    HMURLUploadTask *uploadTask = [_sessionManager uploadTaskWithStreamRequest:request progress:progressBlock completionBlock:completionBlock];
    
    __weak __typeof__(self) weakSelf = self;
    uploadTask.changeStateBlock = ^(HMURLUploadTask * _Nullable uploadTask) {
        __typeof__(self) strongSelf = weakSelf;
        if (uploadTask && [strongSelf.uploadTasks containsObject:uploadTask]) {
            if (strongSelf.delegate) {
                dispatch_async(mainQueue, ^{
                    [strongSelf.delegate hmUploadAdapter:strongSelf didChangeStateUplTask:uploadTask];
                });
            }
        }
    };
    return uploadTask;
}

- (void)subcriptTaskId:(NSUInteger)taskId withIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self) {
        [_uploadSubcription setObject:indexPath forKey:@(taskId)];
    }
}

- (void)unsubcriptTaskId:(NSUInteger)taskId {
    @synchronized(self) {
        [_uploadSubcription removeObjectForKey:@(taskId)];
    }
}

#pragma mark - HMURLSessionManagerDelegate

- (void)hmURLSessionManager:(HMURLSessionManger *)manager didProgressUpdate:(float)progress ofUploadTask:(HMURLUploadTask *)uploadTask {
    if (_delegate) {
        [_delegate hmUploadAdapter:self didProgressUpdate:progress ofUploadTask:uploadTask];
    }
}

- (void)hmURLSessionManager:(HMURLSessionManger *)manager didCompleteUploadTask:(HMURLUploadTask *)uploadTask withError:(NSError *)error {
    if (_delegate) {
        [_delegate hmUploadAdapter:self didCompleteUploadTask:uploadTask withError:error];
    }
}

@end
