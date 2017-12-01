//
//  HMInviteViewController.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NimbusModels.h"
#import "HMContactAdapter.h"

@class HMContactViewController;

@protocol HMContactViewDelegate <NSObject>

- (void)hmContactViewController:(HMContactViewController *)contactVC didSelectModel:(id)model;
- (void)hmContactViewController:(HMContactViewController *)contactVC didDeselectModel:(id)model;
- (BOOL)hmContactViewController:(HMContactViewController *)contactVC checkSelectedModel:(id)model;

@end

@interface HMContactViewController : UITableViewController <UITableViewDelegate, NIMutableTableViewModelDelegate> {
    NSMutableArray *allGroupKeys;
    NSMutableDictionary *groupDict;
    HMContactAdapter *adapter;
    NIMutableTableViewModel *modelDataSource;
}

@property(weak, nonatomic) id<HMContactViewDelegate> delegate;

- (void)setData:(NSArray *)models;
- (void)addData:(NSArray *)models;
- (void)scrollToModel:(id)model;

@end
