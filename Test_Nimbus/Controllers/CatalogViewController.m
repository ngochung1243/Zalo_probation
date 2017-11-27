//
//  ViewController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "CatalogViewController.h"
#import "ContactViewController.h"

@interface CatalogViewController ()

@end

@implementation CatalogViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Catalog";
        
        _action = [[NITableViewActions alloc] initWithTarget:self];
        NSArray *cellContent = @[@"View controller", [_action attachToObject:
                                                      [NITitleCellObject objectWithTitle:@"Contact"]
                                                            navigationBlock:NIPushControllerAction([ContactViewController class])]];
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
