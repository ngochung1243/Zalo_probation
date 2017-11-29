//
//  AppDelegate.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "AppDelegate.h"
#import "HMCatalogViewController.h"
#import "HMContactViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    HMCatalogViewController *catalogVC = [[HMCatalogViewController alloc] init];
    HMContactViewController *contactVC = [[HMContactViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:catalogVC];
    [navigationController.navigationBar setTranslucent:NO];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    
    return YES;
}
@end
