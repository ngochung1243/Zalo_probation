//
//  UIImageView.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/30/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Utils)

- (void)asyncLoadImageWithData:(NSData *)imageData;
- (void)asyncLoadCircleImageWithData:(NSData *)imageData completion:(void(^)(UIImage *image))completionBlock;

@end
