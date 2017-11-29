//
//  HMInviteViewController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactViewController.h"
#import "HMContactAdapter.h"
#import "Constaint.h"

#define TableCellHeight 60

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
}

- (void)setData:(NSArray *)models {
    [[HMContactAdapter shareInstance] prepareDataWithObjectClass:[HMContactTableObject class]
                                                       andModels:models
                                                     groupObject:YES
                                                         inQueue:globalDefaultQueue
                                                      completion:^(NSArray *objects)
    {
        _objects = objects;
        _modelDataSource = [[NIMutableTableViewModel alloc] initWithSectionedArray:objects delegate:self];
        [_modelDataSource setSectionIndexType:NITableViewModelSectionIndexDynamic showsSearch:YES showsSummary:YES];
        self.tableView.dataSource = _modelDataSource;
        [self.tableView reloadData];
    }];
}

- (void)scrollToModel:(id)model {
    if (_objects) {
        [_objects enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj conformsToProtocol:@protocol(HMCellObject)] && [model isEqual:[obj getModel]]) {
                NSIndexPath *indexPath = [_modelDataSource indexPathForObject:obj];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            }
        }];
    }
}

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

- (UITableViewCell *)tableViewModel:(NITableViewModel *)tableViewModel cellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {
    if (_delegate && [object conformsToProtocol:@protocol(HMCellObject)]) {
        BOOL cellSelected = [_delegate hmContactViewController:self checkSelectedModel:[(id<HMCellObject>)object getModel]];
        if (cellSelected) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    return [NICellFactory tableViewModel:tableViewModel cellForTableView:tableView atIndexPath:indexPath withObject:object];
}

- (BOOL)tableViewModel:(NIMutableTableViewModel *)tableViewModel canEditObject:(id)object atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    return YES;
}

@end
