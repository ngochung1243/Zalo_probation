//
//  HMBaseCellObject.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/11/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMCellObject.h"

@implementation HMCellObject

+ (instancetype)objectWithModel:(id)model {
    HMCellObject *cellObject = [[HMCellObject alloc] init];
    cellObject.model = model;
    return cellObject;
}

- (id)getModel {
    return _model;
}

- (NSComparisonResult)compare:(id)object {
    return [self.model compare:((HMCellObject *)object).model];
}

@end
