//
//  ContactModel.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactModel.h"
#import "UIImage+Utils.h"
#import "CNContact+Utils.h"
#import "Constaint.h"

@implementation HMContactModel

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

+ (instancetype)modelWithContact:(CNContact *)contact {
    HMContactModel *model = [[self alloc] init];
    if (model) {
        if (!contact) {
            return model;
        }
        model.firstName = contact.givenName;
        model.lastName = contact.familyName;
        if (contact.imageData) {
            model.imageData = [[UIImage thumbnailImageWithData:contact.imageData andSize:AvatarSize.width] circleWithSize:AvatarSize];
        } else if (contact.thumbnailImageData) {
            model.imageData = [[UIImage thumbnailImageWithData:contact.thumbnailImageData andSize:AvatarSize.width] circleWithSize:AvatarSize];
        } else {
            model.imageData = [UIImage letterImageWithString:contact.fullName textColor:UIColor.whiteColor andBackgroundColor:nil withSize:AvatarSize];
        }
    }
    return model;
}

- (NSString *)fullname {
    return [NSString stringWithFormat:@"%@%@%@", _firstName, ![_lastName isEqualToString:@""] ? @" " : @"", _lastName];
}

- (NSString *)groupName {
    NSString *fullName = [self fullname];
    return fullName.length > 0 ? [fullName substringToIndex:1] : @"";
}

@end
