//
//  HMUploadVC.m
//  ZProbation_UploadTask
//
//  Created by CPU12068 on 12/4/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMUploadViewController.h"
#import "HMURLSessionManger.h"
#import "Constaint.h"
#import "HMUploadAdapter.h"
#import "Masonry.h"
#import "HMAlertUtils.h"
#import "DataFactory.h"
#import "HMUploadTableObject.h"

@interface HMUploadViewController () <UITextFieldDelegate>

@property(strong, nonatomic) HMUploadAdapter *adapter;
@property(strong, nonatomic) NSMutableArray<HMURLUploadTask *> *uploadTasks;
@property(strong, nonatomic) NIMutableTableViewModel *mtblModels;

@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) UIView *headerView;
@property(strong, nonatomic) UILabel *oldMaxCountLbl;
@property(strong, nonatomic) UILabel *maxCountLbl;
@property(strong, nonatomic) UITextField *maxCountTf;
@property(strong, nonatomic) UIButton *setMaxCountBtn;
@property(strong, nonatomic) UIAlertController *fileAlertController;

@property(strong, nonatomic) HMURLUploadProgressBlock progressBlock;
@property(strong, nonatomic) HMURLUploadCompletionBlock completionBlock;
@property(strong, nonatomic) HMURLUploadChangeStateBlock changeStateBlock;


@end

@implementation HMUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _adapter = [HMUploadAdapter shareInstance];
    
    _uploadTasks = [NSMutableArray new];
    _mtblModels = [[NIMutableTableViewModel alloc] initWithListArray:[NSArray new] delegate:(id)[NICellFactory class]];
    
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
    _oldMaxCountLbl.text = [NSString stringWithFormat:@"Current Max: %tu", [_adapter getMaxConcurrentTaskCount]];
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
    _tableView.dataSource = _mtblModels;
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headerView.mas_bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [self setupNavigation];
    [self setupAlertController];
    [self setupCallback];
    [self loadAlreadyTasks];
}

- (void)dealloc {
    NSLog(@"[HM] HMUploadVC - dealloc");
}

#pragma mark - Setup View

- (void)setupNavigation {
    UIBarButtonItem *uploadAllBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", nil) style:UIBarButtonItemStyleDone target:self action:@selector(upload)];
    self.navigationItem.rightBarButtonItem = uploadAllBtn;
    self.navigationItem.title = NSLocalizedString(@"Upload Form", nil);
}

- (void)setupAlertController {
    _fileAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose File", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSString *> *files = [DataFactory generateResourceFileName];
    
    __weak __typeof__(self) weakSelf = self;
    [files enumerateObjectsUsingBlock:^(NSString *  _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:fileName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf showPriorityAlertControllerWithFileName:fileName];
        }];
        
        [_fileAlertController addAction:action];
    }];
    
    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.fileAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    [_fileAlertController addAction:cancelAct];
}

- (void)setupCallback {
    __weak __typeof__(self) weakSelf = self;
    _progressBlock = ^(NSUInteger taskIdentifier, float progress) {
        __typeof__(self) strongSelf = weakSelf;
        if (taskIdentifier == NSNotFound || progress < 0) {
            return;
        }
        
        NSIndexSet *indexSet = [strongSelf.uploadTasks indexesOfObjectsPassingTest:^BOOL(HMURLUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return (obj.currentState != HMURLUploadStateCompleted &&
                     obj.currentState != HMURLUploadStateFailed &&
                     obj.currentState != HMURLUploadStateCancel &&
                    obj.taskIdentifier == taskIdentifier);
        }];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            HMUploadTableCell *cell = [strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
            if (cell) {
                cell.progressView.progress = progress;
            }
        }];
        
        NSLog(@"[HM] UploadTask - Progress: %tu - %f", taskIdentifier, progress);
    };
    
    _completionBlock = ^(NSUInteger taskIdentifier, NSError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (taskIdentifier == NSNotFound) {
            return;
        }
        
        NSIndexSet *indexSet = [strongSelf.uploadTasks indexesOfObjectsPassingTest:^BOOL(HMURLUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return obj.taskIdentifier == taskIdentifier;
        }];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            HMUploadTableCell *cell = [strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
            if (cell) {
                [cell populateData:strongSelf.uploadTasks[idx]];
            }
        }];
        
        NSLog(@"[HM] UploadTask - Complete: %tu - %@", taskIdentifier, error);
    };
    
    _changeStateBlock = ^(NSUInteger taskIdentifier, HMURLUploadState newState) {
        __typeof__(self) strongSelf = weakSelf;
        if (taskIdentifier == NSNotFound) {
            return;
        }
        
        NSIndexSet *indexSet = [strongSelf.uploadTasks indexesOfObjectsPassingTest:^BOOL(HMURLUploadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return obj.taskIdentifier == taskIdentifier;
        }];
        
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            HMUploadTableCell *cell = [strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
            if (cell) {
                [cell populateData:strongSelf.uploadTasks[idx]];
            }
        }];
        
        NSLog(@"[HM] UploadTask - Change state: %tu - %ld", taskIdentifier, newState);
    };
}

#pragma mark - Prepare Data

- (void)loadAlreadyTasks {
    NSArray *alreadyTasks = [_adapter getAlreadyTask];
    if (alreadyTasks) {
        [_uploadTasks addObjectsFromArray:alreadyTasks];
        
        __weak __typeof__(self) weakSelf = self;
        [_uploadTasks enumerateObjectsUsingBlock:^(HMURLUploadTask * _Nonnull uploadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            [uploadTask addCallbacksWithProgressCB:weakSelf.progressBlock
                                      completionCB:weakSelf.completionBlock
                                     changeStateCB:weakSelf.changeStateBlock
                                           inQueue:mainQueue];
            HMUploadTableObject *object = [HMUploadTableObject objectWithModel:uploadTask];
            if (object) {
                [weakSelf.mtblModels addObject:object];
            }
        }];
    }
}

- (void)upload {
    [self presentViewController:_fileAlertController animated:YES completion:nil];
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
        
        __weak __typeof__(self) weakSelf = self;
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf makeUploadTaskWithFileName:fileName priority:priority];
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

    NSArray *nameSeparate = [fileName componentsSeparatedByString:@"."];
    if (nameSeparate.count != 2) {
        return;
    }

    NSString *filePath = [[NSBundle mainBundle] pathForResource:nameSeparate[0] ofType:nameSeparate[1]];
    
    __weak __typeof__(self) weakSelf = self;
    [_adapter uploadTaskWithHost:hostString filePath:filePath header:nil completionHandler:^(HMURLUploadTask * _Nullable uploadTask, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (uploadTask) {
            if (![strongSelf.uploadTasks containsObject:uploadTask]) {
                [uploadTask addCallbacksWithProgressCB:strongSelf.progressBlock
                                          completionCB:strongSelf.completionBlock
                                         changeStateCB:strongSelf.changeStateBlock
                                               inQueue:mainQueue];
            }

            [strongSelf.uploadTasks addObject:uploadTask];
            
            HMUploadTableObject *object = [HMUploadTableObject objectWithModel:uploadTask];
            if (object) {
                [strongSelf.mtblModels addObject:object];
            }
            
            [strongSelf.tableView beginUpdates];
            [strongSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:strongSelf.uploadTasks.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [strongSelf.tableView endUpdates];
        } else if (error) {
            NSLog(@"%@", error);
        }

    } priority:priority inQueue:mainQueue];
}

- (void)setMaxConcurrentTaskCount {
    if ([_oldMaxCountLbl.text isEqualToString:_maxCountTf.text] || [_maxCountTf.text isEqualToString:@""]) {
        return;
    }
    
    UIAlertController *alert = nil;
    if ([_adapter setMaxConcurrentTaskCount:[_maxCountTf.text integerValue]]) {
        _oldMaxCountLbl.text = [NSString stringWithFormat:@"Current Max: %@", _maxCountTf.text];
        alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Set Max-Concur Completed", nil)
                                                                       message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"The current max-concurrent running tasks is", nil), _maxCountTf.text]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
    } else {
        alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Deny request", nil)
                                                    message:NSLocalizedString(@"There are tasks running or pending. Please try again later", nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
    }
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([string rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        return YES;
    }
    
    return NO;
}

@end
