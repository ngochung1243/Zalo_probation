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
    
    NSMutableArray *requestPermissionQueues;
    NSMutableArray *requestAllContactsQueues;
    NSMutableArray *mutableDelegate;
    
    NSError *cachePermissionError;
    BOOL cachePermissionResult;
    NSMutableArray *cacheContacts;
    BOOL isRequestPermission;
    
    BOOL isContactQueueRunning;
    dispatch_queue_t contactSerialQueue;
    
    CNContactStore *contactStore;
    NSTimer *requestContactTimer;
    BOOL isStartedTimer;
}

+ (instancetype)shareInstance;

- (void)addDelegate:(id<HMContactManagerDelegate>)delegate;

- (void)requestPermissionInQueue:(dispatch_queue_t)queue
                      completion:(void(^)(BOOL granted, NSError *error))completionBlock;

- (void)getAllContactsInQueue:(dispatch_queue_t)queue
                   modelClass:(Class<HMContactModel>) modelClass
                   completion:(void(^)(NSArray *contactModels, NSError *error))completionBlock;

- (void)getAllContactsSequenceInQueue:(dispatch_queue_t)queue
                           modelClass:(Class<HMContactModel>) modelClass
                        sequenceCount:(NSUInteger)sequenceCount
                             sequence:(void(^)(NSArray *contactModels))sequenceBlock
                           completion:(void(^)(NSError *error))completionBlock ;

- (void)prepareDataWithObjectClass:(Class<HMCellObject>)objectClass
                         andModels:(NSArray *)models
                       groupObject:(BOOL)groupObject
                           inQueue:(dispatch_queue_t)queue
                        completion:(void (^)(NSArray *objects))completionBlock;

- (BOOL)isGrantedPermission;
- (BOOL)hasAlreadyData;
- (NSArray *)getAlreadyContacts;

- (BOOL)isStartedTimer;
- (BOOL)startFrequentlyGetContactAfterMinute:(long)minute;
- (BOOL)stopFrequentlyGetContact;

@end

