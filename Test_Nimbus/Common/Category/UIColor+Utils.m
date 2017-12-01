//
//  UIColor+Utils.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "UIColor+Utils.h"

@implementation UIColor (Utils)

+ (UIColor *)colorWithHex:(NSString *)hexString {
    assert(7 == hexString.length);
    assert('#' == [hexString characterAtIndex: 0]);
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1];
}

+ (UIColor *)randomColor {
    NSArray *standardColors = @[[UIColor colorWithHex:@"#EFA6A5"],
                                [UIColor colorWithHex:@"#EDBE9A"],
                                [UIColor colorWithHex:@"#88C9DF"],
                                [UIColor colorWithHex:@"#A4C7DC"]];
    return standardColors[rand() % standardColors.count];
}

@end
