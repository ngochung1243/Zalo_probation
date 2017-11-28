//
//  BaseTableViewAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/28/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "BaseTableViewAdapter.h"

@implementation BaseTableViewAdapter

- (void)setData:(NSArray *)data {
    data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        <#code#>
    }
}

- (id<NICellObject>)objectWithData:(id)data {
    return nil;
}

-(void)showSection:(BOOL)showSection {
    self.showSection = showSection;
}

@end
