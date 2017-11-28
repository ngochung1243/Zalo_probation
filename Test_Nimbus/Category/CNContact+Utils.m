//
//  CNContact+Utils.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "CNContact+Utils.h"

@implementation CNContact (Utils)

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@%@%@", self.givenName, ![self.givenName isEqualToString:@""] ? @" " : @"", self.familyName];
}

- (NSArray *)phoneNumberStrings {
    NSMutableArray *phoneStrings = [NSMutableArray new];
    [self.phoneNumbers enumerateObjectsUsingBlock:^(CNLabeledValue *  _Nonnull phoneNumber, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *phoneString = [((CNPhoneNumber *)phoneNumber.value) valueForKey:@"digits"];
        [phoneStrings addObject:phoneString];
    }];
    
    return phoneStrings;
}

@end
