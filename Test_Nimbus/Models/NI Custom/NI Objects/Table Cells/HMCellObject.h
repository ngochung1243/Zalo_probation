//
//  HMBaseCellObject.h
//  Test_Nimbus
//
//  Created by CPU12068 on 12/11/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "NimbusModels.h"

@protocol HMCellObject <NSObject>
+ (instancetype)objectWithModel:(id)model;
- (id)getModel;
- (NSComparisonResult)compare:(id)object;
@end

@interface HMCellObject: NICellObject <HMCellObject>

@property(strong, nonatomic) id model;

@end
