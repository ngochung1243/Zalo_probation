//
//  HMAlertUtils.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMAlertUtils : NSObject

+ (void)showSettingAlertInController:(UIViewController *)controller
                         activeBlock:(void (^)(void))activeBlock
                        passiveBlock:(void (^)(void))passiveBlock;

+ (void)showAlertInController:(UIViewController *)controller
                    withTitle:(NSString *)title
                      message:(NSString *)message
                  activeTitle:(NSString *)activeTitle
                 passiveTitle:(NSString *)passiveTitle
                  activeBlock:(void (^)(void))activeBlock
                 passiveBlock:(void (^)(void))passiveBlock;

@end
