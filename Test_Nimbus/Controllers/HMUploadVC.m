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

@interface HMUploadVC () <UITableViewDataSource, HMUploadAdapterDelegate>

@property(strong, nonatomic) HMUploadAdapter *adapter;
@property(strong, nonatomic) UITableView *tableView;

@end

@implementation HMUploadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _adapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:5];
    _adapter.delegate = self;
    
    // Do any additional setup after loading the view.
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 60)];
    _tableView.backgroundColor = UIColor.whiteColor;
    _tableView.rowHeight = 60;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.dataSource = self;
    [_tableView registerClass:[HMUploadCell class] forCellReuseIdentifier:[HMUploadCell description]];
    [self.view addSubview:_tableView];
    
    [self setupNavigation];
    
    [_adapter getAlreadyTask];
    [_tableView reloadData];
}

- (void)dealloc {
    NSLog(@"[HM] HMUploadVC - dealloc");
}

- (void)setupNavigation {
    UIBarButtonItem *uploadAllBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload All", nil) style:UIBarButtonItemStyleDone target:self action:@selector(uploadAll)];
    self.navigationItem.rightBarButtonItem = uploadAllBtn;
    self.navigationItem.title = NSLocalizedString(@"Upload From", nil);
}

- (void)uploadAll {
    __weak __typeof__(self) weakSelf = self;
    [_adapter uploadNumberOfTask:10 completionHandler:^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _adapter.uploadTasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:[HMUploadCell description] forIndexPath:indexPath];
    HMURLUploadTask *uploadTask = _adapter.uploadTasks[indexPath.row];
    [cell populateData:uploadTask];
    
    [_adapter subcriptTaskId:uploadTask.taskIdentifier withIndexPath:indexPath];
    return cell;
}

#pragma mark - HMUploadDelegateAdapter

- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didProgressUpdate:(float)progress ofUploadTask:(HMURLUploadTask *)uploadTask {
    NSLog(@"[HM] Upload Task - Progress: %ld : %f", uploadTask.taskIdentifier, progress);
    NSIndexPath *indexPath = adapter.uploadSubcription[@(uploadTask.taskIdentifier)];
    HMUploadCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        cell.progressView.progress = progress;
    }
}

- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didCompleteUploadTask:(HMURLUploadTask *)uploadTask withError:(NSError *)error {
    NSLog(@"[HM] Upload Task - Completion: %ld : %@", uploadTask.taskIdentifier, error);
    [adapter unsubcriptTaskId:uploadTask.taskIdentifier];
}

- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didChangeState:(HMURLUploadState)newState ofUploadTask:(HMURLUploadTask *)uploadTask {
    NSUInteger taskIndex = [_adapter.uploadTasks indexOfObject:uploadTask];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:taskIndex inSection:0];
    HMUploadCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell populateData:uploadTask];
    }
}

@end
