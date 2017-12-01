//
//  HMContactAdapter.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMErrorFactory.h"
#import <Contacts/Contacts.h>
#import "NimbusModels.h"
#import "HMContactModel.h"
#import "HMContactTableObject.h"

@class HMContactAdapter;

@interface HMContactAdapter: NSObject {
    NSMutableArray *allGroupKeys;
    NSMutableDictionary *groupDict;
    NSArray *objects;
    
    Class<HMCellObject> objectClass;
    dispatch_queue_t ctAdapterSerialQueue;
}

- (instancetype)initWithObjectClass:(Class<HMCellObject>)objClass;

- (void)setData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void(^)(NSArray *objects))completion;
- (void)addData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void(^)(NSArray *objects))completion;

- (NSArray *)getObjects;

@end
