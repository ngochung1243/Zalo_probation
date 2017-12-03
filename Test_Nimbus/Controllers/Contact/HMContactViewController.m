//
//  HMInviteViewController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactViewController.h"
#import "HMContactManager.h"
#import "Constaint.h"

#define ContactManager              [HMContactManager shareInstance]
#define TableCellHeight             60

@implementation HMContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.rowHeight = TableCellHeight;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView setEditing:YES];
    self.tableView.delegate = self;
    
    allGroupKeys = [NSMutableArray new];
    groupDict = [NSMutableDictionary new];
    adapter = [[HMContactSectionAdapter alloc] initWithObjectClass:[HMCTTableObject class]];
}

#pragma mark - Handle Data

- (void)setData:(NSArray *)models {
    __weak __typeof__(self) weakSelf = self;
    [adapter setData:models returnQueue:nil completion:^(NSArray *objects) {
        weakSelf.modelDataSource = [[NIMutableTableViewModel alloc] initWithSectionedArray:objects delegate:weakSelf];
        [weakSelf.modelDataSource setSectionIndexType:NITableViewModelSectionIndexDynamic showsSearch:YES showsSummary:YES];
        weakSelf.tableView.dataSource = weakSelf.modelDataSource;
        [weakSelf.tableView reloadData];
    }];
}

- (void)addData:(NSArray *)models {
    __weak __typeof__(self) weakSelf = self;
    [adapter addData:models returnQueue:nil completion:^(NSArray *objects) {
        weakSelf.modelDataSource = [[NIMutableTableViewModel alloc] initWithSectionedArray:objects delegate:weakSelf];
        [weakSelf.modelDataSource setSectionIndexType:NITableViewModelSectionIndexDynamic showsSearch:YES showsSummary:YES];
        weakSelf.tableView.dataSource = weakSelf.modelDataSource;
        [weakSelf.tableView reloadData];
    }];
}

- (void)scrollToModel:(id)model {
    NSArray *objects = [adapter getObjects];
    if (!objects) {
        return;
    }
    
    [objects enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(HMCellObject)] && [model isEqual:[obj getModel]]) {
            NSIndexPath *indexPath = [_modelDataSource indexPathForObject:obj];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<HMCellObject> object = [_modelDataSource objectAtIndexPath:indexPath];
    NSAssert([object conformsToProtocol:@protocol(HMCellObject)], @"Target object is not conformed to HMCellObject protocol");
    if (_delegate) {
        [_delegate hmContactViewController:self didSelectModel:[object getModel]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<HMCellObject> object = [_modelDataSource objectAtIndexPath:indexPath];
    NSAssert([object conformsToProtocol:@protocol(HMCellObject)], @"Target object is not conformed to HMCellObject protocol");
    if (_delegate) {
        [_delegate hmContactViewController:self didDeselectModel:[object getModel]];
    }
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selectedBackgroundView.hidden = NO;
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selectedBackgroundView.hidden = YES;
}

#pragma mark - NITableViewModelDelegate

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel cellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {
    if (_delegate && [object conformsToProtocol:@protocol(HMCellObject)]) {
        BOOL cellSelected = [_delegate hmContactViewController:self checkSelectedModel:[(id<HMCellObject>)object getModel]];
        if (cellSelected) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        return [NICellFactory tableViewModel:tableViewModel cellForTableView:tableView atIndexPath:indexPath withObject:object];
    }
    return [[UITableViewCell alloc] init];
}

- (BOOL)tableViewModel:(NIMutableTableViewModel *)tableViewModel canEditObject:(id)object atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

@end
