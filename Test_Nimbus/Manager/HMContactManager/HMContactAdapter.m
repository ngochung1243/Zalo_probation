//
//  HMContactAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactAdapter.h"
#import "Constaint.h"
#import "HMAlertUtils.h"
#import "HMContactQueueEntity.h"

#pragma mark - HMContactAdapter Base Class
@implementation HMContactAdapter

- (instancetype)initWithObjectClass:(Class<HMCellObject>)objClass {
    if (self = [super init]) {
        objects = [NSMutableArray new];
        
        objectClass = objClass;
        ctAdapterSerialQueue = dispatch_queue_create("vn.com.hungmai.ctAdapterSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - Public

- (void)setData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void (^)(NSArray *))completion{
    NSAssert(ctAdapterSerialQueue, @"Contact adapter serial queue is nil. Please initilize before using it");
    [objects removeAllObjects];
}

- (void)addData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void (^)(NSArray *))completion{
    NSAssert(ctAdapterSerialQueue, @"Contact adapter serial queue is nil. Please initilize before using it");
}

- (NSArray *)getObjects {
    return objects;
}

- (dispatch_queue_t)getReturnQueueWithQueue:(dispatch_queue_t)queue {
    return queue ? queue : mainQueue;
}

- (NSUInteger)getIndexOfObject:(id)object shouldAddInArray:(NSArray *)array {
    NSUInteger newIndex = [array indexOfObject:object inSortedRange:(NSRange){0, array.count} options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    
    return newIndex;
}
@end



#pragma mark - HMContactListAdapter Inheritance Class

@implementation HMContactListAdapter

#pragma mark - Public

- (void)setData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void (^)(NSArray *))completion {
    [super setData:models returnQueue:queue completion:completion];
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(ctAdapterSerialQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        
        NSArray *sortedModels = [models sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        
        [sortedModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj && [obj isKindOfClass:[HMContactModel class]]) {
                id object = [objectClass objectWithModel:obj];
                if (object) {
                    [strongSelf->objects addObject:object];
                }
            }
        }];
        
        dispatch_async(returnQueue, ^{
            if (completion) {
                completion(strongSelf->objects);
            }
        });
    });
}

- (void)addData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void (^)(NSArray *))completion {
    [super addData:models returnQueue:queue completion:completion];
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(ctAdapterSerialQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        
        [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id object = [objectClass objectWithModel:obj];
            NSUInteger newIndex = [strongSelf getIndexOfObject:object shouldAddInArray:strongSelf->objects];
            [strongSelf->objects insertObject:object atIndex:newIndex];
            
            dispatch_async(returnQueue, ^{
                if (completion) {
                    completion(strongSelf->objects);
                }
            });
        }];
    });
}

@end


#pragma mark - HMContactSectionAdapter Inheritance Class

@implementation HMContactSectionAdapter

- (instancetype)initWithObjectClass:(Class<HMCellObject>)objClass {
    if (self = [super initWithObjectClass:objClass]) {
        allGroupKeys = [NSMutableArray new];
        groupDict = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark - Public

- (void)setData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void (^)(NSArray *))completion {
    [super setData:models returnQueue:queue completion:completion];
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(ctAdapterSerialQueue, ^{
        __typeof__(self) strongSelf = weakSelf;
        strongSelf->groupDict = [[weakSelf groupModels:models] mutableCopy];
        strongSelf->allGroupKeys = [[weakSelf getAllGroupKeysWithDictionary:groupDict] mutableCopy];
        strongSelf->objects = [[weakSelf generateObjects] mutableCopy];
        
        dispatch_async(returnQueue, ^{
            if (completion) {
                completion(strongSelf->objects);
            }
        });
    });
}

- (void)addData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void (^)(NSArray *))completion {
    [super addData:models returnQueue:queue completion:completion];
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(ctAdapterSerialQueue, ^{
        __typeof__(self) strongSelf = self;
        [weakSelf addModels:models];
        objects = [[weakSelf generateObjects] mutableCopy];
        
        dispatch_async(returnQueue, ^{
            if (completion) {
                completion(strongSelf->objects);
            }
        });
    });
}

#pragma mark - Private

//Group contact with first character name
- (NSDictionary *)groupModels:(NSArray *)models{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [models enumerateObjectsUsingBlock:^(id<HMContactModel>  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([model conformsToProtocol:@protocol(HMContactModel)], @"You should pass a model implemented HMContactModel protocol");
        
        //Check params is valid
        if (!model || !dict) {
            return;
        }
        
        id object = [objectClass objectWithModel:model];
        
        NSString *firstCharacter = [model groupName];
        NSMutableArray *groupContactArray = [dict objectForKey:firstCharacter];
        if (!groupContactArray) {
            groupContactArray = [NSMutableArray new];
            [dict setObject:groupContactArray forKey:firstCharacter];
        }
        [groupContactArray addObject:object];
    }];
    
    return dict;
}

- (NSArray *)getAllGroupKeysWithDictionary:(NSDictionary *)dictionary {
    NSArray *allGroupKey = [dictionary allKeys]; //Get all characters section
    
    //Sort alphabet characters
    allGroupKey = [allGroupKey sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return allGroupKey;
}

//Add and short new models to stored models
- (void)addModels:(NSArray *)models {
    NSMutableArray *newSectionsIndex = [NSMutableArray new];
    NSMutableArray *newIndexPathsIndex = [NSMutableArray new];
    [models enumerateObjectsUsingBlock:^(id<HMContactModel>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id object = [objectClass objectWithModel:obj];
        __block BOOL addedObject = NO;
        if ([obj conformsToProtocol:@protocol(HMContactModel)]) {
            NSString *targetGroupKey = [obj groupName];
            NSUInteger keyCount = allGroupKeys.count;
            for (int i = 0; i < keyCount; i ++) {
                NSString *groupKey = allGroupKeys[i];
                NSInteger sectionIndex = -1;
                NSInteger rowIndex = -1;
                BOOL newSection = NO;
                if (![groupKey isKindOfClass:[NSString class]]) {
                    continue;
                }
                
                if ([groupKey isEqualToString:targetGroupKey]) {
                    NSMutableArray *groupArray = [groupDict objectForKey:groupKey];
                    [groupArray addObject:object];
                    sectionIndex = i;
                    rowIndex = groupArray.count - 1;
                } else if ([groupKey compare:targetGroupKey] == kCFCompareGreaterThan) {
                    [allGroupKeys insertObject:targetGroupKey atIndex:i];
                    NSMutableArray *newArray = [NSMutableArray new];
                    [newArray addObject:object];
                    [groupDict setObject:newArray forKey:targetGroupKey];
                    sectionIndex = idx;
                    rowIndex = 0;
                    newSection = YES;
                    
                    keyCount += 1;
                    i += 1;
                }
                if (sectionIndex != -1 && rowIndex != -1) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                    [newIndexPathsIndex addObject:indexPath];
                    if (newSection) {
                        [newSectionsIndex addObject:[NSNumber numberWithInteger:sectionIndex]];
                    }
                    addedObject = YES;
                    return;
                }
            }
            
            if (!addedObject) {
                [allGroupKeys addObject:targetGroupKey];
                NSMutableArray *newArray = [NSMutableArray new];
                [newArray addObject:object];
                [groupDict setObject:newArray forKey:targetGroupKey];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:allGroupKeys.count - 1];
                [newSectionsIndex addObject:[NSNumber numberWithInteger:allGroupKeys.count - 1]];
                [newIndexPathsIndex addObject:indexPath];
            }
        }
    }];
}

//Create all objects with stored group model dictionary
- (NSArray *)generateObjects {
    NSMutableArray *contentData = [NSMutableArray new];
    [allGroupKeys enumerateObjectsUsingBlock:^(id  _Nonnull groupKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!groupKey || ![groupKey isKindOfClass:[NSString class]]) {
            return;
        }
        
        [contentData addObject:groupKey];
        NSArray *objects = [groupDict objectForKey:groupKey];
        if (objects) {
            [objects enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                if (object) {
                    [contentData addObject:object];
                }
            }];
        }
    }];
    
    return contentData;
}

@end
