//
//  HMPriorityQueue.m
//  Test_Nimbus
//
//  Created by CPU12068 on 12/7/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMPriorityQueue.h"
#import <Foundation/Foundation.h>

@interface HMPriorityQueue<ObjectType>()

@property(strong, nonatomic) NSMutableArray<ObjectType> *array;

@end

@implementation HMPriorityQueue

- (instancetype)init {
    if (self = [super init]) {
        _array = [NSMutableArray new];
    }
    return self;
}

- (void)pushObject:(id)object {
    NSInteger addIndex = [self binaryFindIndexWithObject:object fromIndex:0 toIndex:_array.count];
    [_array insertObject:object atIndex:addIndex];
}

- (id)popObject {
    id object = [_array objectAtIndex:0];
    [_array removeObjectAtIndex:0];
    return object;
}

- (void)removeObject:(id)object {
    [_array removeObject:object];
}

- (BOOL)containsObject:(id)object {
    return [_array containsObject:object];
}

- (NSArray *)allObjects {
    return [_array copy];
}

#pragma mark - Set attributes

- (NSUInteger)count {
    return _array.count;
}

#pragma mark - Private

- (NSInteger)binaryFindIndexWithObject:(id)object fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSInteger midIndex = (toIndex - fromIndex) / 2 + fromIndex;
    
    if (fromIndex >= toIndex) {
        return toIndex;
    }
    
    if ([_array[midIndex] compare:object] == NSOrderedAscending) {
        return [self binaryFindIndexWithObject:object fromIndex:fromIndex toIndex:midIndex];
        
    } else if ([_array[midIndex] compare:object] == NSOrderedDescending) {
        return [self binaryFindIndexWithObject:object fromIndex:midIndex + 1 toIndex:toIndex];
        
    } else {
        NSInteger tempIndex = midIndex + 1;
        while (tempIndex < _array.count) {
            if ([_array[tempIndex] compare:_array[midIndex]] == NSOrderedDescending) {
                return tempIndex;
            }
            
            tempIndex += 1;
        }
        
        return tempIndex;
    }
}


@end
