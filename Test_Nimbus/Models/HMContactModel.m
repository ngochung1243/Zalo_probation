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
        _identifier = @"";
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
        model.identifier = contact.identifier;
        model.firstName = contact.givenName;
        model.lastName = contact.familyName;
        model.groupName = [model getGroupName];
        if (contact.thumbnailImageData) {
            model.imageData = contact.thumbnailImageData;
        } else if (contact.imageData) {
            model.imageData = contact.imageData;
        }
    }
    return model;
}

- (NSString *)fullname {
    NSString *fullName = [NSString stringWithFormat:@"%@%@%@", _firstName, ![_lastName isEqualToString:@""] ? @" " : @"", _lastName];
    fullName = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return fullName;
}

- (NSString *)groupName {
    return _groupName;
}

- (NSString *)getGroupName {
    NSString *fullName = [self fullname];
    NSString *gName;
    if (fullName.length > 0) {
        unichar c = [fullName characterAtIndex:0];
        gName = [NSString stringWithFormat:@"%C", c];
    }
    gName = [gName stringByReplacingOccurrencesOfString:@"đ" withString:@"d"];
    gName = [gName stringByReplacingOccurrencesOfString:@"Đ" withString:@"D"];
    NSData *decode = [gName dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    gName = [[NSString alloc] initWithData:decode encoding:NSASCIIStringEncoding];
    gName = [gName uppercaseString];
    return gName;
}

@end
