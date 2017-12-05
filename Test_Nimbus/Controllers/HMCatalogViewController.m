//
//  ViewController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMCatalogViewController.h"
#import "HMInviteContactController.h"
#import "HMUploadVC.h"

@interface HMCatalogViewController ()

@end

@implementation HMCatalogViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Catalog", nil);
        
        _action = [[NITableViewActions alloc] initWithTarget:self];
        NSArray *cellContent = @[NSLocalizedString(@"View Controllers", nil),
                                 [_action attachToObject: [NITitleCellObject objectWithTitle:NSLocalizedString(@"Contact", nil)]
                                         navigationBlock:NIPushControllerAction([HMInviteContactController class])],
                                 [_action attachToObject: [NITitleCellObject objectWithTitle:NSLocalizedString(@"Upload", nil)]
                                         navigationBlock:NIPushControllerAction([HMUploadVC class])]];
        _models = [[NITableViewModel alloc] initWithSectionedArray:cellContent delegate:(id)[NICellFactory class]];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = _models;
    self.tableView.delegate = [_action forwardingTo:self];
}

@end
