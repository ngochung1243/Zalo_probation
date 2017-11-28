//
//  TransparentSearchBar.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/28/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "TransparentSearchBar.h"

@implementation TransparentSearchBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
                [subview removeFromSuperview];
                break;
            }
            for (UIView *subsubview in subview.subviews) {
                if ([subsubview isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
                    [subsubview removeFromSuperview];
                    break;
                }
            }
        }
    }
    return self;
}

@end
