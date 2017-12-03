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

@property(strong, nonatomic) NSMutableArray *permissionReqEntities;
@property(strong, nonatomic) NSMutableArray *contactReqEntities;

@property(strong, nonatomic) CNContactStore *contactStore;
@property(strong, nonatomic) NSMutableArray *cacheContacts;

@property(strong, nonatomic) dispatch_queue_t contactSerialQueue;

@property(nonatomic) BOOL isQueueRunning;

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
        
        _isQueueRunning = NO;
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
    @synchronized(self) {
        NSAssert(_contactSerialQueue, @"Can't request contact permission. Contact serial queue is not initilized");
        
        HMCTPermissionEntity *perEntity = [[HMCTPermissionEntity alloc] initWithBlock:completionBlock inQueue:queue];
        if (_permissionReqEntities) {
            [_permissionReqEntities addObject:perEntity];
        }
        
        if (_isQueueRunning) {
            return;
        }
        
        _isQueueRunning = YES;
        dispatch_async(_contactSerialQueue, ^{
            NSLog(@"[HM] Request permission: queue start");
            
            [_contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                [_permissionReqEntities enumerateObjectsUsingBlock:^(HMCTPermissionEntity*  _Nonnull entity, NSUInteger idx, BOOL * _Nonnull stop) {
                    dispatch_async(entity.queue, ^{
                        if (entity.permissionBlock) {
                            NSLog(@"[HM] Request permission: queue return");
                            entity.permissionBlock(granted, error);
                        }
                    });
                }];
                _isQueueRunning = NO;
            }];
        });
    }
}

- (void)getAllContactsWithBlock:(HMCTGettingBlock)completionBlock inQueue:(dispatch_queue_t)queue {
    @synchronized(self) {
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
        } inQueue:queue];
    }
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
    @synchronized(self) {
        HMCTGettingEntity *getEntity = [[HMCTGettingEntity alloc] initWithBlock:completionBlock inQueue:queue];
        if (getEntity) {
            [_contactReqEntities addObject:getEntity];
        }
        
        if (_isQueueRunning) {
            return;
        }
        
        _isQueueRunning = YES;
        dispatch_async(_contactSerialQueue, ^{ //Get all contacts in serial queue for multiple requests purport
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
            
            [_contactReqEntities enumerateObjectsUsingBlock:^(HMCTGettingEntity*  _Nonnull entity, NSUInteger idx, BOOL * _Nonnull stop) {
                dispatch_async(entity.queue, ^{ //Return the result with the completion block in the queue user want to handle
                    NSLog(@"[HM] Request contacts: queue return");
                    if (entity.gettingBlock) {
                        entity.gettingBlock(_cacheContacts, nil);
                    }
                });
            }];
            NSLog(@"[HM] Request contacts: allow queue");
            _isQueueRunning = NO;
        });
    }
}

@end

