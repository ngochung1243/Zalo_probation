//
//  Z_NITableViewModel.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "Z_NITableViewModel.h"
#import "NITableViewModel+Private.h"
#import "NimbusModels.h"

@implementation Z_NITableViewModel

- (id)objectWithObjectValue:(id)value {
    if (nil == value) {
        return nil;
    }
    
    NSArray *sections = self.sections;
    for (NSUInteger sectionIndex = 0; sectionIndex < [sections count]; sectionIndex++) {
        NSArray* rows = [[sections objectAtIndex:sectionIndex] rows];
        for (NSUInteger rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
            id object = [rows objectAtIndex:rowIndex];
            if ([object isKindOfClass:[NIDrawRectBlockCellObject class]]) {
                if ([value isEqual:((NIDrawRectBlockCellObject *)object).object]) {
                    return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                }
            }
        }
    }
    
    return nil;
}

@end
