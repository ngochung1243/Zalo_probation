//
//  UIImage+Utils.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSString+Utils.h"

@interface UIImage (Utils)

+ (UIImage *)defaultCircleImageWithSize:(CGSize)size; //Make circle image with gray background
+ (UIImage *)letterImageWithString:(NSString *)string textColor:(UIColor *)textColor andBackgroundColor:(UIColor *)backgroundColor withSize:(CGSize)size; //Make character image
+ (UIImage *)thumbnailImageWithData:(NSData *)imageData andSize:(CGFloat)maxPixelSize; //Get thumbnail image with data

- (UIImage *)circleWithSize:(CGSize)size; //Get circle image of an image
- (UIImage *)thumbnailWithSize:(CGFloat)maxPixelSize; //Get thumbnail image from origin image

@end
