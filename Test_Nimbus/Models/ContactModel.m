//
//  ContactModel.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ContactModel.h"
#import "UIImage+Utils.h"
#import "CNContact+Utils.h"
#import "Constaint.h"

@implementation ContactModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firstName = @"";
        _lastName = @"";
        _imageData = nil;
    }
    return self;
}

- (instancetype)initWithCNContact:(CNContact *)contact {
    if (self = [self init]) {
        if (!contact) {
            return self;
        }
        _firstName = contact.givenName;
        _lastName = contact.familyName;
        if (contact.imageData) {
            _imageData = [UIImage imageWithData:contact.imageData];
        } else if (contact.thumbnailImageData) {
            _imageData = [UIImage imageWithData:contact.thumbnailImageData];
        } else {
            _imageData = [UIImage letterImageWithString:contact.fullName textColor:UIColor.whiteColor andBackgroundColor:nil withSize:AvatarSize];
        }
    }
    return self;
}

- (NSString *)fullname {
    return [NSString stringWithFormat:@"%@%@%@", _firstName, ![_lastName isEqualToString:@""] ? @" " : @"", _lastName];
}

@end
