//
//  UIImage+Utils.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "UIImage+Utils.h"
#import "UIColor+Utils.h"

@implementation UIImage (Utils)

+ (UIImage *)defaultCircleImageWithSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextSetFillColorWithColor(context, UIColor.lightGrayColor.CGColor);
    CGContextFillEllipseInRect(context, rect);
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

+ (UIImage *)letterImageWithString:(NSString *)string textColor:(UIColor *)textColor andBackgroundColor:(UIColor *)backgroundColor withSize:(CGSize)size{
    if (!backgroundColor) {
        backgroundColor = [UIColor randomColor];
    }
    if (!textColor) {
        textColor = UIColor.whiteColor;
    }
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, rect);
    
    UIFont *textFont = [UIFont systemFontOfSize:size.height - 25];
    NSString *letterString = [string filter2LetterInString];
    CGSize stringSize = [letterString sizeWithAttributes:@{NSFontAttributeName: textFont}];
    [letterString drawAtPoint:CGPointMake(CGRectGetMidX(rect) - stringSize.width/2, CGRectGetMidY(rect) - stringSize.height/2) withAttributes:@{NSFontAttributeName: textFont, NSForegroundColorAttributeName: textColor}];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (UIImage *)circleWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:size.height/2] addClip];
    [self drawInRect:rect];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

@end
