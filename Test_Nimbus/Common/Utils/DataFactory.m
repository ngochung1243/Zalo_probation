//
//  DataFactory.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "DataFactory.h"

@implementation DataFactory

+ (NSArray *)getAllContacts {
    return nil;
}


#pragma mark - Support for HMUploadViewController

+ (NSArray<NSString *> *)generateResourceFileName {
    return @[@"GoTiengViet.dmg",
             @"videoplayback.mp4",
             @"fullhd.jpg", @"Compare.zip",
             @"Request.zip",
             @"Reboot.dmg"];
}



@end
