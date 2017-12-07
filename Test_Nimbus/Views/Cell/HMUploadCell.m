//
//  HMUploadCell.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/5/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadCell.h"
#import "Masonry.h"

#define HMUploadCellBtnSize         CGSizeMake(20, 20)

@implementation HMUploadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _taskIdentifier = 0;
        
        _progressView = [UIProgressView new];
        _progressView.progress = 0;
        _progressView.layer.cornerRadius = 5;
        _progressView.backgroundColor = self.contentView.backgroundColor;
        _progressView.clipsToBounds = YES;
        [self.contentView addSubview:_progressView];
        [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(10);
            make.left.equalTo(self.contentView).offset(10);
            make.right.equalTo(self.contentView).offset(-10);
            make.height.mas_equalTo(10);
        }];
        
        _resumeBtn = [UIButton new];
        [_resumeBtn setImage:[UIImage imageNamed:@"ic_pause"] forState:UIControlStateNormal];
        _resumeBtn.tintColor = UIColor.blueColor;
        _resumeBtn.backgroundColor = self.contentView.backgroundColor;
        [_resumeBtn addTarget:self action:@selector(addTarget:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_resumeBtn];
        [_resumeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_progressView.mas_bottom).offset(10);
            make.left.equalTo(_progressView);
            make.size.mas_equalTo(HMUploadCellBtnSize);
        }];
        
        
        _cancelBtn = [UIButton new];
        [_cancelBtn setImage:[UIImage imageNamed:@"ic_cancel"] forState:UIControlStateNormal];
        _cancelBtn.tintColor = UIColor.blackColor;
        _cancelBtn.backgroundColor = self.contentView.backgroundColor;
        [_cancelBtn addTarget:self action:@selector(addTarget:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_cancelBtn];
        [_cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_resumeBtn);
            make.left.equalTo(_resumeBtn.mas_right).offset(10);
            make.size.mas_equalTo(HMUploadCellBtnSize);
        }];
        
        _fileNameLbl = [UILabel new];
        _fileNameLbl.textColor = UIColor.blackColor;
        [self.contentView addSubview:_fileNameLbl];
        [_fileNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_resumeBtn);
            make.left.equalTo(_cancelBtn.mas_right).offset(10);
        }];
        
        _statusImv = [UIImageView new];
        _statusImv.image = [UIImage imageNamed:@"ic_success"];
        _statusImv.hidden = YES;
        _statusImv.backgroundColor = self.contentView.backgroundColor;
        [self.contentView addSubview:_statusImv];
        [_statusImv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_resumeBtn);
            make.right.equalTo(self.contentView).offset(-10);
            make.size.mas_equalTo(HMUploadCellBtnSize);
        }];
    }
    
    return self;
}

#pragma mark - Public

- (void)populateData:(HMURLUploadTask *)uploadTask {
    @synchronized(self) {
        _uploadTask = uploadTask;
        _taskIdentifier = uploadTask.taskIdentifier;
        _progressView.progress = uploadTask.uploadProgress;
        _fileNameLbl.text = [uploadTask.filePath lastPathComponent];
        
        switch (uploadTask.currentState) {
            case HMURLUploadStateNotRunning:
            case HMURLUploadStateRunning:
            case HMURLUploadStatePaused:
                _statusImv.hidden = YES;
                _resumeBtn.hidden = NO;
                _cancelBtn.hidden = NO;
                break;
                
            case HMURLUploadStateCompleted:
            case HMURLUploadStateFailed:
            case HMURLUploadStateCancel:
                _statusImv.hidden = NO;
                _resumeBtn.hidden = YES;
                _cancelBtn.hidden = YES;
                break;
                
            case HMURLUploadStatePending:
                _statusImv.hidden = NO;
                _resumeBtn.hidden = NO;
                _cancelBtn.hidden = NO;

            default:
                break;
        }
        
        switch (uploadTask.currentState) {
            case HMURLUploadStateNotRunning:
            case HMURLUploadStatePaused:
                [_resumeBtn setImage:[UIImage imageNamed:@"ic_resume"] forState:UIControlStateNormal];
                break;
            case HMURLUploadStateRunning:
            case HMURLUploadStatePending:
                [_resumeBtn setImage:[UIImage imageNamed:@"ic_pause"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
        
        switch (uploadTask.currentState) {
            case HMURLUploadStatePending:
                _statusImv.image = [UIImage imageNamed:@"ic_pending"];
                break;
            case HMURLUploadStateCompleted:
                _statusImv.image = [UIImage imageNamed:@"ic_success"];
                break;
            case HMURLUploadStateFailed:
            case HMURLUploadStateCancel:
                _statusImv.image = [UIImage imageNamed:@"ic_error"];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - Private

- (void)addTarget:(UIButton *)button {
    if (!_uploadTask) {
        return;
    }
    
    if ([button isEqual:_resumeBtn]) {
        if (_uploadTask.currentState == HMURLUploadStateNotRunning || _uploadTask.currentState == HMURLUploadStatePaused) {
            [_uploadTask resume];
        } else if (_uploadTask.currentState == HMURLUploadStateRunning) {
            [_uploadTask pause];
        }
    } else if ([button isEqual:_cancelBtn]) {
        [_uploadTask cancel];
    }
}

@end
