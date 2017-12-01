//
//  HMImageMemoryCache.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "NIInMemoryCache.h"
#import <UIKit/UIKit.h>

@interface HMImageMemoryCache : NIImageMemoryCache

+ (instancetype)shareInstance;

@end
