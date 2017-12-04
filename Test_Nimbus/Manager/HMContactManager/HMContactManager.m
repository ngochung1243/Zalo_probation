//
//  HMContactAdapter.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactManager.h"
#import "Constaint.h"
#import "HMAlertUtils.h"

@interface HMContactManager()

@property(strong, nonatomic) NSMutableArray<HMCTPermissionEntity *> *permissionReqEntities;
@property(strong, nonatomic) NSMutableArray<HMCTGettingEntity *> *contactReqEntities;

@property(strong, nonatomic) CNContactStore *contactStore;
@property(strong, nonatomic) NSMutableArray<HMContactModel *> *cacheContacts;

@property(strong, nonatomic) dispatch_queue_t contactSerialQueue;

@property(nonatomic) BOOL needToWaitReqPermission;
@property(nonatomic) BOOL needToWaitReqContacts;

@end

@implementation HMContactManager

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        _contactStore = [[CNContactStore alloc] init];
        _contactSerialQueue = dispatch_queue_create("vn.com.hungmai.contactSerialQueue", DISPATCH_QUEUE_SERIAL);
        _permissionReqEntities = [NSMutableArray new];
        _contactReqEntities = [NSMutableArray new];
        _cacheContacts = [NSMutableArray new];
        
        _needToWaitReqPermission = NO;
    }
    
    return self;
}

#pragma mark - Static

+ (instancetype)shareInstance {
    static HMContactManager *shareInstance;
    static dispatch_once_t dispatch_once_queue;
    dispatch_once(&dispatch_once_queue, ^{
        shareInstance = [[self alloc] initPrivate];
    });
    
    return shareInstance;
}

#pragma mark - Public

- (void)requestPermissionWithBlock:(HMCTPermissionBlock)completionBlock inQueue:(dispatch_queue_t)queue {
    dispatch_async(_contactSerialQueue, ^{
        NSAssert(_contactSerialQueue, @"Can't request contact permission. Contact serial queue is not initilized");
        
        HMCTPermissionEntity *perEntity = [[HMCTPermissionEntity alloc] initWithBlock:completionBlock inQueue:queue];
        if (_permissionReqEntities) {
            [_permissionReqEntities addObject:perEntity];
        }
        
        if (_needToWaitReqPermission) {
            return;
        }
        
        _needToWaitReqPermission = YES;
        dispatch_async(globalDefaultQueue, ^{
            NSLog(@"[HM] Request permission: queue start");
            
            [_contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                dispatch_async(_contactSerialQueue, ^{
                    [_permissionReqEntities enumerateObjectsUsingBlock:^(HMCTPermissionEntity*  _Nonnull entity, NSUInteger idx, BOOL * _Nonnull stop) {
                        dispatch_async(entity.queue, ^{
                            if (entity.permissionBlock) {
                                NSLog(@"[HM] Request permission: queue %ld return", idx);
                                entity.permissionBlock(granted, error);
                            }
                        });
                    }];
                    [_permissionReqEntities removeAllObjects];
                    _needToWaitReqPermission = NO;
                });
            }];
        });
    });
}

- (void)getAllContactsWithBlock:(HMCTGettingBlock)completionBlock inQueue:(dispatch_queue_t)queue {
    NSAssert(_contactSerialQueue, @"Can't get contacts. Contact serial queue is not initilized");
    
    //Request permission before requesting all contacts
    __weak __typeof__(self) weakSelf = self;
    [weakSelf requestPermissionWithBlock:^(BOOL granted, NSError *error) {
        if (error) {
            if (completionBlock) {
                completionBlock(nil, error);
            }
            
            return;
        }
        
        [weakSelf allowGetAllContactsWithBlock:completionBlock inQueue:queue];
    } inQueue:_contactSerialQueue];
}

- (BOOL)hasAlreadyData {
    return _cacheContacts.count > 0 ? YES : NO;
}

- (NSArray *)getAlreadyContacts {
    return _cacheContacts;
}

#pragma mark - Private

//Get all contact when passing contact permission
- (void)allowGetAllContactsWithBlock:(void (^)(NSArray *, NSError *))completionBlock inQueue:(dispatch_queue_t)queue {
    NSLog(@"[HM] Request contacts: queue begin");
    HMCTGettingEntity *getEntity = [[HMCTGettingEntity alloc] initWithBlock:completionBlock inQueue:queue];
    if (getEntity) {
        [_contactReqEntities addObject:getEntity];
    }
    
    if (_needToWaitReqContacts) {
        return;
    }
    
    _needToWaitReqContacts = YES;
    dispatch_async(globalDefaultQueue, ^{ //Get all contacts in serial queue for multiple requests purport
        NSLog(@"[HM] Request contacts: queue start");
        
        [_cacheContacts removeAllObjects];
        
        NSMutableArray *models = [NSMutableArray new];
        
        NSArray *keysToFetch = @[CNContactEmailAddressesKey,
                                 CNContactFamilyNameKey,
                                 CNContactGivenNameKey,
                                 CNContactPhoneNumbersKey,
                                 CNContactImageDataKey,
                                 CNContactThumbnailImageDataKey];
        
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        NSError *error;
        
        [_contactStore enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            id model = [HMContactModel modelWithContact:contact];
            [models addObject:model];
        }];
        
        [_cacheContacts addObjectsFromArray:models];
        
        dispatch_async(_contactSerialQueue, ^{
            [_contactReqEntities enumerateObjectsUsingBlock:^(HMCTGettingEntity*  _Nonnull entity, NSUInteger idx, BOOL * _Nonnull stop) {
                dispatch_async(entity.queue, ^{ //Return the result with the completion block in the queue user want to handle
                    NSLog(@"[HM] Request contacts: queue %ld return", idx);
                    if (entity.gettingBlock) {
                        entity.gettingBlock(_cacheContacts, nil);
                    }
                });
            }];
            
            [_contactReqEntities removeAllObjects];
            _needToWaitReqContacts = NO;
        });
    });
}

@end

