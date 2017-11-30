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
    
    allGroupKeys = [NSMutableArray new];
    groupDict = [NSMutableDictionary new];
    
    _modelDataSource = [[NIMutableTableViewModel alloc] initWithSectionedArray:[NSMutableArray new] delegate:self];
    [_modelDataSource setSectionIndexType:NITableViewModelSectionIndexDynamic showsSearch:YES showsSummary:YES];
    self.tableView.dataSource = _modelDataSource;
}

- (void)setData:(NSArray *)models {
    [[HMContactAdapter shareInstance] prepareDataWithObjectClass:[HMContactTableObject class]
                                                       andModels:models
                                                     groupObject:YES
                                                         inQueue:globalDefaultQueue
                                                      completion:^(NSArray *objects)
    {
        _objects = [objects mutableCopy];
        
        [_modelDataSource addObjectsFromArray:objects];
        [self.tableView reloadData];
    }];
}

- (void)addData:(NSArray *)models {
    NSMutableArray *newSectionsIndex = [NSMutableArray new];
    NSMutableArray *newIndexPathsIndex = [NSMutableArray new];
    [models enumerateObjectsUsingBlock:^(id<HMContactModel>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id object = [HMContactTableObject objectWithModel:obj];
        __block BOOL addedObject = NO;
        if ([obj conformsToProtocol:@protocol(HMContactModel)]) {
            NSString *targetGroupKey = [obj groupName];
            NSUInteger keyCount = allGroupKeys.count;
            for (int i = 0; i < keyCount; i ++) {
                NSString *groupKey = allGroupKeys[i];
                NSInteger sectionIndex = -1;
                NSInteger rowIndex = -1;
                BOOL newSection = NO;
                if (![groupKey isKindOfClass:[NSString class]]) {
                    continue;
                }
                
                if ([groupKey isEqualToString:targetGroupKey]) {
                    NSMutableArray *groupArray = [groupDict objectForKey:groupKey];
                    [groupArray addObject:object];
                    sectionIndex = i;
                    rowIndex = groupArray.count - 1;
                } else if ([groupKey compare:targetGroupKey] == kCFCompareGreaterThan) {
                    [allGroupKeys insertObject:targetGroupKey atIndex:i];
                    NSMutableArray *newArray = [NSMutableArray new];
                    [newArray addObject:object];
                    [groupDict setObject:newArray forKey:targetGroupKey];
                    sectionIndex = idx;
                    rowIndex = 0;
                    newSection = YES;
                    
                    keyCount += 1;
                    i += 1;
                }
                if (sectionIndex != -1 && rowIndex != -1) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                    [newIndexPathsIndex addObject:indexPath];
                    if (newSection) {
                        [newSectionsIndex addObject:[NSNumber numberWithInteger:sectionIndex]];
                    }
                    addedObject = YES;
                    return;
                }
            }
            
            if (!addedObject) {
                [allGroupKeys addObject:targetGroupKey];
                NSMutableArray *newArray = [NSMutableArray new];
                [newArray addObject:object];
                [groupDict setObject:newArray forKey:targetGroupKey];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:allGroupKeys.count - 1];
                [newSectionsIndex addObject:[NSNumber numberWithInteger:allGroupKeys.count - 1]];
                [newIndexPathsIndex addObject:indexPath];
            }
        }
    }];
    
    [self loadData];
}

- (void)loadData {
    NSMutableArray *contentData = [NSMutableArray new];
    [allGroupKeys enumerateObjectsUsingBlock:^(id  _Nonnull groupKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!groupKey || ![groupKey isKindOfClass:[NSString class]]) {
            return;
        }
        
        [contentData addObject:groupKey];
        NSArray *objects = [groupDict objectForKey:groupKey];
        if (objects) {
            [objects enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                if (object) {
                    [contentData addObject:object];
                }
            }];
        }
    }];
    
    _modelDataSource = [[NIMutableTableViewModel alloc] initWithSectionedArray:contentData delegate:self];
    [_modelDataSource setSectionIndexType:NITableViewModelSectionIndexDynamic showsSearch:YES showsSummary:YES];
    self.tableView.dataSource = _modelDataSource;
    [self.tableView reloadData];
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
