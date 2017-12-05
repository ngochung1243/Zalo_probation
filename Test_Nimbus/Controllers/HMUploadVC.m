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
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    _tableView.backgroundColor = UIColor.whiteColor;
    _tableView.rowHeight = 60;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.dataSource = self;
    [_tableView registerClass:[HMUploadCell class] forCellReuseIdentifier:[HMUploadCell description]];
    [self.view addSubview:_tableView];
    
    [self setupNavigation];
}

- (void)setupNavigation {
    UIBarButtonItem *uploadAllBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload All", nil) style:UIBarButtonItemStyleDone target:self action:@selector(uploadAll)];
    self.navigationItem.rightBarButtonItem = uploadAllBtn;
    self.navigationItem.title = NSLocalizedString(@"Upload From", nil);
}

- (void)uploadAll {
    [_adapter uploadNumberOfTask:10 progress:^(NSUInteger taskIdentifier, float progress) {
        NSLog(@"[HM] Upload Task - Progress: %ld : %f", taskIdentifier, progress);
        HMUploadCell *subcriptCell = _adapter.uploadSubcription[@(taskIdentifier)];
        if (subcriptCell) {
            subcriptCell.progressView.progress = progress;
        }
    } completionBlock:^(NSUInteger taskIdentifier, NSURLResponse * _Nonnull reponse, NSError * _Nullable error) {
        NSLog(@"[HM] Upload Task - Completion: %ld : %@", taskIdentifier, error);
    }];
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _adapter.uploadTasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:[HMUploadCell description] forIndexPath:indexPath];
    HMURLUploadTask *uploadTask = _adapter.uploadTasks[indexPath.row];
    [cell populateData:uploadTask];
    
    [_adapter unsubcriptCell:cell];
    
    cell.taskIdentifier = uploadTask.taskIdentifier;
    [_adapter subcriptCell:cell];
    return cell;
}

#pragma mark - HMUploadDelegateAdapter

- (void)hmUploadAdapter:(HMUploadAdapter *)adapter didChangeStateUplTaskAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView beginUpdates];
    [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [_tableView endUpdates];
}

@end
