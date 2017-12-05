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
#import "HMCTTableObject.h"

@interface HMContactAdapter: NSObject {
    NSMutableArray *objects;
    
    Class<HMCellObject> objectClass;
    dispatch_queue_t ctAdapterSerialQueue;
}

/**
 Initialize an instance with a defined class which will use for making table datasource

 @param objClass The class which will use for making table datasource
 @return An instance
 */
- (instancetype)initWithObjectClass:(Class<HMCellObject>)objClass;

/**
Set data for adapter to making the objects using for table view datasouce

 @param models The data using for making the objects
 @param queue The return queue handling the completion
 @param completion The block using for the completion
 */
- (void)setData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void(^)(NSArray *objects))completion;

/**
 Add another data to stored data and make the objects for these data

 @param models The data need to add
 @param queue The return queue handling the completion
 @param completion The block using for the completion
 */
- (void)addData:(NSArray *)models returnQueue:(dispatch_queue_t)queue completion:(void(^)(NSArray *objects))completion;

/**
 Get stored objects of adapter

 @return The array of stored objects
 */
- (NSArray *)getObjects;

@end



/**
 The class used for non section table view datasource
 */
@interface HMContactListAdapter: HMContactAdapter
@end



/**
 The class used for section table view datasource
 */
@interface HMContactSectionAdapter: HMContactAdapter {
    NSMutableArray *allGroupKeys;
    NSMutableDictionary *groupDict;
}

@end
