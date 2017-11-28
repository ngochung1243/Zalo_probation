//
//  ContactViewController.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Contacts/Contacts.h>
#import "NimbusModels.h"
#import "NimbusCollections.h"
#import "ContactBarView.h"
#import "ContactTableObject.h"
#import "Z_NITableViewModel.h"
#import "TransparentSearchBar.h"

#pragma mark - Inheritant

@interface ContactModelDelegate: NICellFactory
@end

@interface ContactTableViewModel: Z_NITableViewModel
@property(strong, nonatomic) NSMutableArray *pickContacts;
@end

#pragma mark - Contact View Controller

@interface ContactViewController : UIViewController <UITableViewDelegate, UISearchBarDelegate>

@property(strong, nonatomic) NSMutableDictionary *contacts;
@property(strong, nonatomic) NITableViewActions *actions;
@property(strong, nonatomic) ContactTableViewModel *modelDataSource;
@property(strong, nonatomic) ContactBarView *contactBarView;
@property(strong, nonatomic) TransparentSearchBar *searchBar;
@property(strong, nonatomic) UITableView *tableView;

@end
