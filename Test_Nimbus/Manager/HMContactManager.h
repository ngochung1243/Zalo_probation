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
#import "HMContactQueueEntity.h"

@interface HMContactManager : NSObject

+ (instancetype)shareInstance;

/**
 Request contact permission in background serial queue

 @param queue The return queue
 @param completionBlock The block handling the result
 */
- (void)requestPermissionWithBlock:(HMCTPermissionBlock)completionBlock inQueue:(dispatch_queue_t)queue;


/**
 Get all contacts in device in background serial queue. The function will request contact permission before.

 @param queue The return queue
 @param completionBlock The block handling the result
 */
- (void)getAllContactsWithBlock:(HMCTGettingBlock)completionBlock inQueue:(dispatch_queue_t)queue;


/**
 Check whether the contacts list is cached or not

 @return TRUE if cached the contacts list
 */
- (BOOL)hasAlreadyData;


/**
 Get cached contacts list

 @return The array of cached contacts list
 */
- (NSArray *)getAlreadyContacts;

@end

