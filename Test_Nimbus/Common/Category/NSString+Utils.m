//
//  NSString+Utils.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

- (NSString *)filter2LetterInString {
    
    NSCharacterSet *notAllowSet = [NSCharacterSet characterSetWithCharactersInString:@"~`!@#$%^&*()+=-/;:\"\'{}[]<>^?,."];
    NSString *correctString = [[self componentsSeparatedByCharactersInSet:notAllowSet] componentsJoinedByString:@""];
    correctString = [correctString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *stringComponent = [correctString componentsSeparatedByString:@" "];
    if (stringComponent.count == 0) {
        return @"";
    }
    
    NSString *firstPart = stringComponent[0];
    NSString *lastPart = stringComponent[stringComponent.count - 1];
    
    if (firstPart == lastPart) {
        for (int i = 0; i < firstPart.length; i ++) {
        }
        return [[firstPart substringToIndex:MIN(2, firstPart.length)] uppercaseString];
    } else {
        return [[NSString stringWithFormat:@"%C%C", [firstPart characterAtIndex:0], [lastPart characterAtIndex:0]] uppercaseString];
    }
    return @"";
}

@end
