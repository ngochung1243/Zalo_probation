//
//  HMInviteContactController.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMTransparentSearchBar.h"
#import "HMContactViewController.h"
#import "HMPickedContactController.h"
#import "HMContactAdapter.h"

@interface HMInviteContactController : UIViewController <UISearchBarDelegate, HMContactViewDelegate, HMPickedContactDelegate>

@property(strong, nonatomic) NSMutableArray *contacts;

@property(strong, nonatomic) UIView *headerView;
@property(strong, nonatomic) HMTransparentSearchBar *searchBarView;
@property(strong, nonatomic) UIView *contentView;

@property(strong, nonatomic) HMContactViewController *contactVC;
@property(strong, nonatomic) HMPickedContactController *pickedContactVC;

@end
