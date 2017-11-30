//
//  UIImageView.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "UIImageView+Utils.h"
#import "Constaint.h"
#import "UIImage+Utils.h"

@implementation UIImageView (Utils)

- (void)asyncLoadImageWithData:(NSData *)imageData{
    if (!imageData) {
        return;
    }
    
    dispatch_async(globalDefaultQueue, ^{
        UIImage *image = [[UIImage imageWithData:imageData] thumbnailWithSize:self.frame.size.width];
        dispatch_async(mainQueue, ^{
            self.image = image;
        });
    });
}

- (void)asyncLoadCircleImageWithData:(NSData *)imageData completion:(void (^)(UIImage *))completionBlock {
    if (!imageData) {
        return;
    }
    
    CGSize viewSize = self.frame.size;
    
    dispatch_async(globalDefaultQueue, ^{
        UIImage *image = [[UIImage thumbnailImageWithData:imageData andSize:viewSize.width] circleWithSize:viewSize];
        dispatch_async(mainQueue, ^{
            self.image = image;
            completionBlock(image);
        });
    });
}


@end
