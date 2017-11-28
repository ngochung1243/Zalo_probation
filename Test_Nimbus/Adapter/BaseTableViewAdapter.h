//
//  BaseTableViewAdapter.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/28/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NimbusModels.h"

@protocol TableViewAdapterDelegate  <NSObject>
@property(nonatomic) BOOL showSection;
@property(weak, nonatomic) UITableView *tableView;

- (id<NICellObject>)objectWithData:(id)data;
- (NSString *)sectionTitleWithObject:(id)object;

- (void)setData:(NSArray *)data;
- (void)add:(id)object;
- (void)remove:(id)object;
- (void)removeAtIndexPath:(NSIndexPath *)indexPath;
- (void)filterWithObject:(id)object;
- (void)showSection:(BOOL)showSection;

@end

@interface BaseTableViewAdapter : NSObject <TableViewAdapterDelegate>

@end
