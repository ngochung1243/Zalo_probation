//
//  HMUploadCell.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMURLUploadTask.h"

@interface HMUploadCell : UITableViewCell
@property(nonatomic) NSUInteger taskIdentifier;
@property(strong, nonatomic) HMURLUploadTask *uploadTask;

@property(strong, nonatomic) UIProgressView *progressView;
@property(strong, nonatomic) UIButton *resumeBtn;
@property(strong, nonatomic) UIButton *cancelBtn;
@property(strong, nonatomic) UIImageView *statusImv;

@property(weak, nonatomic) void(^resumeBlock)(void);
@property(weak, nonatomic) void(^pauseBlock)(void);
@property(weak, nonatomic) void(^cancelBlock)(void);

- (void)populateData:(HMURLUploadTask *)uploadTask;

@end
