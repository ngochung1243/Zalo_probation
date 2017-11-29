//
//  HMAlertUtils.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMAlertUtils.h"

#define DefaultSettingTitle         NSLocalizedString(@"Important", nil)
#define DefaultSettingMessage       NSLocalizedString(@"Permission denied. Please go to Settings and allow permissions", nil)
#define DefaultCancelActionTitle    NSLocalizedString(@"Cancel", nil)
#define DefaultSettingActionTitle   NSLocalizedString(@"Settings", nil)

@implementation HMAlertUtils

+ (void)showSettingAlertInController:(UIViewController *)controller activeBlock:(void (^)(void))activeBlock passiveBlock:(void (^)(void))passiveBlock {
    [self showAlertInController:controller
                      withTitle:DefaultSettingTitle
                        message:DefaultSettingMessage
                    activeTitle:DefaultSettingActionTitle
                   passiveTitle:DefaultCancelActionTitle
                    activeBlock:activeBlock
                   passiveBlock:passiveBlock];
}

+ (void)showAlertInController:(UIViewController *)controller
                    withTitle:(NSString *)title
                      message:(NSString *)message
                  activeTitle:(NSString *)activeTitle
                 passiveTitle:(NSString *)passiveTitle
                  activeBlock:(void (^)(void))activeBlock
                 passiveBlock:(void (^)(void))passiveBlock {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *activeAction = [UIAlertAction actionWithTitle:activeTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (activeBlock) {
            activeBlock();
        }
    }];
    UIAlertAction *passiveAction = [UIAlertAction actionWithTitle:passiveTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (passiveBlock) {
            passiveBlock();
        }
        
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alertController addAction:activeAction];
    [alertController addAction:passiveAction];
    [controller presentViewController:alertController animated:YES completion:nil];
}

@end
