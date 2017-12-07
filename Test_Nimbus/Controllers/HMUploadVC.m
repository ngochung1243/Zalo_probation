//
//  HMUploadVC.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadVC.h"
#import "HMURLSessionManger.h"
#import "HMUploadCell.h"
#import "Constaint.h"
#import "HMUploadAdapter.h"
#import "Masonry.h"

@interface HMUploadVC () <UITableViewDataSource, UITextFieldDelegate>

@property(strong, nonatomic) HMUploadAdapter *adapter;
@property(strong, nonatomic) NSMutableArray<HMURLUploadTask *> *uploadTasks;

@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) UIView *headerView;
@property(strong, nonatomic) UILabel *oldMaxCountLbl;
@property(strong, nonatomic) UILabel *maxCountLbl;
@property(strong, nonatomic) UITextField *maxCountTf;
@property(strong, nonatomic) UIButton *setMaxCountBtn;
@property(strong, nonatomic) UIAlertController *fileAlertController;


@end

@implementation HMUploadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _adapter = [HMUploadAdapter shareInstance];
    [_adapter setMaxConcurrentTaskCount:1];
    
    _uploadTasks = [NSMutableArray new];
    
    // Do any additional setup after loading the view.
    _headerView = [UIView new];
    _headerView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:_headerView];
    [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.mas_equalTo(40);
    }];
    
    _oldMaxCountLbl = [UILabel new];
    _oldMaxCountLbl.textColor = UIColor.whiteColor;
    _oldMaxCountLbl.text = [NSString stringWithFormat:@"Old Max: %d", 1];
    [_headerView addSubview:_oldMaxCountLbl];
    [_oldMaxCountLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_headerView);
        make.left.equalTo(_headerView).offset(10);
    }];
    
    _maxCountLbl = [UILabel new];
    _maxCountLbl.textColor = UIColor.whiteColor;
    _maxCountLbl.text = NSLocalizedString(@"New Max", nil);
    [_headerView addSubview:_maxCountLbl];
    [_maxCountLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_headerView);
        make.left.equalTo(_oldMaxCountLbl.mas_right).offset(40);
    }];
    
    _maxCountTf = [UITextField new];
    _maxCountTf.backgroundColor = UIColor.whiteColor;
    _maxCountTf.layer.cornerRadius = 5;
    _maxCountTf.textAlignment = NSTextAlignmentCenter;
    _maxCountTf.delegate = self;
    [_headerView addSubview:_maxCountTf];
    [_maxCountTf mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_headerView);
        make.left.equalTo(_maxCountLbl.mas_right).offset(5);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    _setMaxCountBtn = [UIButton new];
    [_setMaxCountBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [_setMaxCountBtn setTitle:NSLocalizedString(@"Set", nil) forState:UIControlStateNormal];
    [_setMaxCountBtn addTarget:self action:@selector(setMaxConcurrentTaskCount) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_setMaxCountBtn];
    [_setMaxCountBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_headerView);
        make.right.equalTo(_headerView).offset(-10);
        make.size.mas_equalTo(CGSizeMake(40, 30));
    }];
    
    _tableView = [UITableView new];
    _tableView.backgroundColor = UIColor.whiteColor;
    _tableView.rowHeight = 60;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.dataSource = self;
    [_tableView registerClass:[HMUploadCell class] forCellReuseIdentifier:[HMUploadCell description]];
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headerView.mas_bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [self setupNavigation];
    [self setupAlertController];
}

- (void)dealloc {
    NSLog(@"[HM] HMUploadVC - dealloc");
}

- (void)setupNavigation {
    UIBarButtonItem *uploadAllBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", nil) style:UIBarButtonItemStyleDone target:self action:@selector(upload)];
    self.navigationItem.rightBarButtonItem = uploadAllBtn;
    self.navigationItem.title = NSLocalizedString(@"Upload Form", nil);
}

- (void)upload {
    [self presentViewController:_fileAlertController animated:YES completion:nil];
}

- (void)setupAlertController {
    _fileAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose File", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSString *> *files = @[@"GoTiengViet.dmg", @"videoplayback.mp4", @"fullhd.jpg"];
    
    [files enumerateObjectsUsingBlock:^(NSString *  _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:fileName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showPriorityAlertControllerWithFileName:fileName];
        }];
        
        [_fileAlertController addAction:action];
    }];
    
    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [_fileAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    [_fileAlertController addAction:cancelAct];
}



- (void)showPriorityAlertControllerWithFileName:(NSString *)fileName {
    NSArray *priorities = @[@(HMURLUploadTaskPriorityHigh), @(HMURLUploadTaskPriorityMedium), @(HMURLUploadTaskPriorityLow)];
    UIAlertController *priorityAC = [UIAlertController alertControllerWithTitle:@"Choose Priority" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [priorities enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HMURLUploadTaskPriority priority = [obj integerValue];
        NSString *title = @"";
        switch (priority) {
            case HMURLUploadTaskPriorityHigh:
                title = @"High";
                break;
            case HMURLUploadTaskPriorityMedium:
                title = @"Medium";
                break;
            case HMURLUploadTaskPriorityLow:
                title = @"Low";
                break;
            default:
                break;
        }
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self makeUploadTaskWithFileName:fileName priority:priority];
        }];
        
        [priorityAC addAction:action];
    }];
    
    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [priorityAC dismissViewControllerAnimated:YES completion:nil];
    }];
    [priorityAC addAction:cancelAct];
    
    [self presentViewController:priorityAC animated:YES completion:nil];
}

- (void)makeUploadTaskWithFileName:(NSString *)fileName priority:(HMURLUploadTaskPriority)priority {
    NSString *hostString = @"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung";
    
    HMURLUploadProgressBlock progressBlock = ^(HMURLUploadTask * _Nonnull uploadTask, float progress) {
        if (uploadTask) {
            NSIndexSet *indexSet = [_uploadTasks indexesOfObjectsPassingTest:^BOOL(HMURLUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj isEqual:uploadTask];
            }];
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                HMUploadCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
                if (cell) {
                    cell.progressView.progress = progress;
                }
            }];
        }
        
        NSLog(@"[HM] UploadTask - Progress: %tu - %f", uploadTask.taskIdentifier, progress);
    };
    
    HMURLUploadCompletionBlock completionBlock = ^(HMURLUploadTask * _Nonnull uploadTask, NSError * _Nullable error) {
        NSIndexSet *indexSet = [_uploadTasks indexesOfObjectsPassingTest:^BOOL(HMURLUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj isEqual:uploadTask];
        }];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            HMUploadCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
            if (cell) {
                [cell populateData:uploadTask];
            }
        }];
        
        NSLog(@"[HM] UploadTask - Complete: %tu - %@", uploadTask.taskIdentifier, error);
    };
    
    HMURLUploadChangeStateBlock changeStateBlock = ^(HMURLUploadTask * _Nonnull uploadTask, HMURLUploadState newState) {
        NSIndexSet *indexSet = [_uploadTasks indexesOfObjectsPassingTest:^BOOL(HMURLUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj isEqual:uploadTask];
        }];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            HMUploadCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
            if (cell) {
                [cell populateData:uploadTask];
            }
        }];
        
        NSLog(@"[HM] UploadTask - Change state: %tu - %ld", uploadTask.taskIdentifier, newState);
    };
    
    NSArray *nameSeparate = [fileName componentsSeparatedByString:@"."];
    if (nameSeparate.count != 2) {
        return;
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:nameSeparate[0] ofType:nameSeparate[1]];
    
    [_adapter uploadTaskWithHost:hostString filePath:filePath header:nil completionHandler:^(HMURLUploadTask * _Nullable uploadTask) {
        if (uploadTask) {
            if (![_uploadTasks containsObject:uploadTask]) {
                [uploadTask addProgressCallback:progressBlock];
                [uploadTask addCompletionCallback:completionBlock];
                [uploadTask addChangeStateCallback:changeStateBlock];
            } else {
                //                        [uploadTask resume];
            }
            
            [_uploadTasks addObject:uploadTask];
            [_tableView beginUpdates];
            [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_uploadTasks.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [_tableView endUpdates];
        }
        
    } priority:priority inQueue:mainQueue];
}

- (void)setMaxConcurrentTaskCount {
    if ([_oldMaxCountLbl.text isEqualToString:_maxCountLbl.text]) {
        return;
    }
    
    if ([_adapter setMaxConcurrentTaskCount:[_maxCountTf.text integerValue]]) {
        _oldMaxCountLbl.text = [NSString stringWithFormat:@"Old Max: %@", _maxCountTf.text];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Deny request" message:@"There are tasks running or pending. Please try again later" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _uploadTasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:[HMUploadCell description] forIndexPath:indexPath];
    HMURLUploadTask *uploadTask = _uploadTasks[indexPath.row];
    [cell populateData:uploadTask];

    return cell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([string rangeOfCharacterFromSet:notDigits].location == NSNotFound)
    {
        return YES;
    }
    
    return NO;
}

@end
