//
//  ViewController.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NimbusModels.h"

@interface CatalogViewController: UITableViewController

@property(strong, nonatomic) NITableViewModel *models;
@property(strong, nonatomic) NITableViewActions *action;

@end

