//
//  HMContactAdapter.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMErrorFactory.h"
#import <Contacts/Contacts.h>
#import "NimbusModels.h"
#import "HMContactModel.h"
#import "HMContactTableObject.h"

@class HMContactAdapter;

@interface HMContactAdapter : NSObject {
    CNContactStore *contactStore;
}

+ (instancetype)shareInstance;

- (void)requestPermissionInQueue:(dispatch_queue_t)queue
                        completion:(void(^)(BOOL granted, NSError *error))completionBlock;

- (void)getAllContactsInQueue:(dispatch_queue_t)queue
                   modelClass:(Class<HMContactModel>) modelClass
                   completion:(void(^)(NSArray *contactModels, NSError *error))completionBlock;

- (void)prepareDataWithObjectClass:(Class<HMCellObject>)objectClass
                         andModels:(NSArray *)models
                       groupObject:(BOOL)groupObject
                           inQueue:(dispatch_queue_t)queue
                        completion:(void (^)(NSArray *objects))completionBlock;

- (BOOL)isGrantedPermission;

@end
