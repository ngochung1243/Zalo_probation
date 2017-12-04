//
//  HMUploadVC.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadVC.h"
#import "HMURLSessionManger.h"

@interface HMUploadVC ()
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation HMUploadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _progressView.progress = 0;
}

- (IBAction)startUpload:(id)sender {
    NSDictionary *headers = @{ @"content-type": @"multipart/form-data" };
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"fullhd" withExtension:@"jpg"];

    HMURLSessionManger *sessionManager = [[HMURLSessionManger alloc] initWithConfiguration:nil];
    for (int i = 0; i < 10; i ++) {
        HMURLUploadTask *uploadTask = [sessionManager uploadTaskWithRequest:request fromFile:fileUrl progress:^(float progress) {
            NSLog(@"[HM] Upload file: %d - %f", i, progress);
        } completionBlock:^(NSURLResponse * _Nonnull reponse, NSError * _Nullable error) {
            if (error) {
                NSLog(@"[HM] Upload file: %d - Error", i);
            } else {
                NSLog(@"[HM] Upload file: %d - Complete", i);
            }
        }];
        [uploadTask resume];
    }
}
@end
