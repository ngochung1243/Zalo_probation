//
//  HMContactNavBarController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/1/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactNavBarController.h"
#import "Masonry.h"
#import "Constaint.h"

#define NavPadding              UIEdgeInsetsMake(0, 20, 0, 20)
#define BackButtonSize          CGSizeMake(40, 30)
#define TitleFontSize           25
#define TitleViewMaxWidth       200

@implementation HMContactNavBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _backButton = [[UIButton alloc] init];
    [_backButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [_backButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [self.view addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view);
        make.left.equalTo(self.view).offset(NavPadding.left);
        make.size.mas_equalTo(BackButtonSize);
    }];
    
    _titleView = [[UIView alloc] init];
    _titleView.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:_titleView];
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view);
        make.height.equalTo(self.view);
        make.width.mas_equalTo(TitleViewMaxWidth);
    }];
}

@end
