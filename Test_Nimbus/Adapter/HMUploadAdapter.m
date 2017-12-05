//
//  HMUploadAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadAdapter.h"

@interface HMUploadAdapter()

@property(strong, nonatomic) HMURLSessionManger *sessionManager;

@end

@implementation HMUploadAdapter

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount {
    if (self = [super init]) {
        _uploadTasks = [NSMutableArray new];
        _uploadSubcription = [NSMutableDictionary new];
        _sessionManager = [[HMURLSessionManger alloc] initWithMaxConcurrentTaskCount:maxCount andConfiguration:nil];
    }
    return self;
}

- (void)uploadNumberOfTask:(NSUInteger)numberTasks progress:(HMUploadProgressBlock)progressBlock completionBlock:(HMUploadCompletionBlock)completionBlock {
    for (int i = 0; i < numberTasks; i ++) {
        HMURLUploadTask *uploadTask = [self createUploadTaskWithProgress:progressBlock completionBlock:completionBlock];
        if (uploadTask) {
            [_uploadTasks addObject:uploadTask];
        }
        [uploadTask resume];
    }
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
    
    HMURLUploadTask *uploadTask = [_sessionManager dataTaskWithRequest:request progress:^(NSUInteger taskIdentifier, float progress) {
        NSLog(@"[HM] Upload Task - Progress: %ld : %f", taskIdentifier, progress);
        HMUploadCell *subcriptCell = _uploadSubcription[@(taskIdentifier)];
        if (subcriptCell) {
            subcriptCell.progressView.progress = progress;
        }
    } completionBlock:^(NSUInteger taskIdentifier, NSURLResponse * _Nonnull reponse, NSError * _Nullable error) {
        NSLog(@"[HM] Upload Task - Completion: %ld : %@", taskIdentifier, error);
    }];
    
    __weak __typeof__(self) weakSelf = self;
    
    uploadTask.changeStateBlock = ^(HMURLUploadTask * _Nullable uploadTask) {
        __typeof__(self) strongSelf = weakSelf;
        if (uploadTask && [strongSelf.uploadTasks containsObject:uploadTask]) {
            NSUInteger taskIndex = [strongSelf.uploadTasks indexOfObject:uploadTask];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:taskIndex inSection:0];
            if (_delegate) {
                [_delegate hmUploadAdapter:strongSelf didChangeStateUplTaskAtIndexPath:indexPath];
            }
        }
    };
    return uploadTask;
}

- (void)subcriptCell:(HMUploadCell *)cell {
    @synchronized(self) {
        [_uploadSubcription setObject:cell forKey:@(cell.taskIdentifier)];
    }
}

- (void)unsubcriptCell:(HMUploadCell *)cell {
    @synchronized(self) {
        [_uploadSubcription removeObjectForKey:@(cell.taskIdentifier)];
    }
}

@end
