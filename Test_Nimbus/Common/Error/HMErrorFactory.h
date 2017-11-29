//
//  ErrorFactory.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kErrorMessage       @"kErrorMessage"
#define kErrorCode          @"kErrorCode"
#define kErrorType          @"kErrorType"

typedef NS_ENUM(NSInteger, HMErrorFactoryType) {
    HMErrorFactoryTypePermission,
    HMErrorFactoryTypeNetwork,
};

typedef NS_ENUM(NSInteger, HMPermissionErrorType) {
    HMPermissionErrorTypeNotDetermined = 1,
    HMPermissionErrorTypeDenied,
    HMPermissionErrorTypeRestricted,
    HMPermissionErrorTypeUnknown
};

@interface HMError: NSError
@property(copy, nonatomic) NSString *message;
@property(assign, nonatomic) NSInteger errorCode;

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo;
@end


@interface HMPermissionError: HMError
@property(assign, nonatomic) HMPermissionErrorType errorType;
@end


@interface HMErrorFactory: NSObject
+ (NSError *)makeErrorWithFactoryType:(HMErrorFactoryType)factoryType withParamsDict:(NSDictionary *)dictionary;
@end
