//
//  HMImageMemoryCache.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMImageMemoryCache.h"

@implementation HMImageMemoryCache

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithCapacity:(NSUInteger)capacity {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivate {
    return [super initWithCapacity:0];
}

+ (instancetype)shareInstance {
    static HMImageMemoryCache *shareInstace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstace = [[self alloc] initPrivate];
    });
    
    return shareInstace;
}
@end
