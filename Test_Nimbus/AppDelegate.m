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
#import "HMImageMemoryCache.h"
#import "HMUploadAdapter.h"
#import "HMNetworkManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    HMCatalogViewController *catalogVC = [[HMCatalogViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:catalogVC];
    [navigationController.navigationBar setTranslucent:NO];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    [HMImageMemoryCache shareInstance].maxNumberOfPixels = 1024 * 1024 * 10; //10m pixel
    
    //Set background fetch
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if ([HMNetworkManager shareInstance].isReachable) {
        [[HMUploadAdapter shareInstance] resumeAllTask];
    }
}

@end
