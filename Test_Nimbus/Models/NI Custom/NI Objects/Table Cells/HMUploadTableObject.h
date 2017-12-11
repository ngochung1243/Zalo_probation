//
//  HMUploadTableObject.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/11/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "NICellFactory.h"
#import "HMCellObject.h"
#import "HMURLUploadTask.h"

@interface HMUploadTableObject: HMCellObject
@end





@interface HMUploadTableCell: UITableViewCell <NICell>

@property(nonatomic) NSUInteger taskIdentifier;
@property(strong, nonatomic) HMURLUploadTask *uploadTask;

@property(strong, nonatomic) UIProgressView *progressView;
@property(strong, nonatomic) UIButton *resumeBtn;
@property(strong, nonatomic) UIButton *cancelBtn;
@property(strong, nonatomic) UILabel *fileNameLbl;
@property(strong, nonatomic) UIImageView *statusImv;

- (void)populateData:(HMURLUploadTask *)uploadTask;

@end
