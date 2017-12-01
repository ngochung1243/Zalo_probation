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

@class HMContactManager;

@protocol HMContactManagerDelegate <NSObject>

- (void)hmContactManager:(HMContactManager *)manager didReceiveContactsRequently:(NSArray *)contacts;

@end

@interface HMContactManager : NSObject {
    NSMutableArray *mutableDelegate;
    
    NSError *cachePermissionError;
    BOOL cachePermissionResult;
    NSMutableArray *cacheContacts;
    BOOL isRequestPermission;
    BOOL isGetedContacts;
    NSDate *lastUpdate;
    double updateTimeInterval;
    
    dispatch_queue_t contactSerialQueue;
    
    CNContactStore *contactStore;
    NSTimer *requestContactTimer;
    BOOL isStartedTimer;
}


+ (instancetype)shareInstance;


/**
 Add a delegate to stored delegate for multiple callback

 @param delegate The delegate wanted to get callback
 */
- (void)addDelegate:(id<HMContactManagerDelegate>)delegate;


/**
 Request contact permission in background serial queue

 @param queue The return queue
 @param completionBlock The block handling the result
 */
- (void)requestPermissionInQueue:(dispatch_queue_t)queue
                      completion:(void(^)(BOOL granted, NSError *error))completionBlock;


/**
 Get all contacts in device in background serial queue. The function will request contact permission before.

 @param queue The return queue
 @param modelClass The class which will use for creating contact model. This class must be conformed to HMContactModel protocol
 @param completionBlock The block handling the result
 */
- (void)getAllContactsWithReturnQueue:(dispatch_queue_t)queue
                   modelClass:(Class<HMContactModel>) modelClass
                   completion:(void(^)(NSArray *contactModels, NSError *error))completionBlock;


/**
 Get all contacts with multiple callback to caller when receiving enough contact models the caller wanted during requesting contact

 @param queue The return queue
 @param modelClass The class which will use for creating contact model. This class must be conformed to HMContactModel protocol
 @param sequenceCount The number of contact models the caller wanted
 @param sequenceBlock The block which will call several times when receiving enoungh contact models the caller wanted
 @param completionBlock The block handling the result
 */
- (void)getAllContactsSeqWithReturnQueue:(dispatch_queue_t)queue
                           modelClass:(Class<HMContactModel>) modelClass
                        sequenceCount:(NSUInteger)sequenceCount
                             sequence:(void(^)(NSArray *contactModels))sequenceBlock
                           completion:(void(^)(NSError *error))completionBlock ;


/**
 Check whether permission is granted or not

 @return TRUE if permission is granted
 */
- (BOOL)isGrantedPermission;

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

/**
 Allow users can set the time interval using for getting all contacts again

 @param second The time interval
 */
- (void)setUpdateTimeIntervalWithSecond:(double)second;

/**
 Check whether the timer for repeatedly getting all contacts request is started or not

 @return TRUE if the timer is started
 */
- (BOOL)isStartedTimer;

/**
 Start the timer used for repeated getting all contacts request

 @param minute The minute time value for repeated time interval
 @return TRUE if the timer begin being started
 */
- (BOOL)startFrequentlyGetContactAfterMinute:(long)minute;

/**
 Stop the timer used for repeated getting all contacts request

 @return TRUE if the timer is stoped
 */
- (BOOL)stopFrequentlyGetContact;

@end

