//
//  ErrorFactory.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMErrorFactory.h"

@implementation HMError

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo {
    NSString *message = [userInfo objectForKey:kErrorMessage];
    NSInteger errorCode = [[userInfo objectForKey:kErrorCode] integerValue];
    if (self = [super initWithDomain:@"" code:errorCode userInfo:userInfo]) {
        _message = message;
        _errorCode = errorCode;
    }
    
    return self;
}

@end

@implementation HMPermissionError
@end

@implementation HMErrorFactory

+ (NSError *)makeErrorWithFactoryType:(HMErrorFactoryType)factoryType withParamsDict:(NSDictionary *)dictionary {
    NSError *error = nil;
    switch (factoryType) {
        case HMErrorFactoryTypePermission: {
            error = [[HMPermissionError alloc] initWithUserInfo:dictionary];
            HMPermissionErrorType errorType = [[dictionary objectForKey:kErrorType] integerValue];
            ((HMPermissionError *)error).errorType = errorType;
            break;
        }
        
        default:
            break;
    }
    
    return error;
}

@end
