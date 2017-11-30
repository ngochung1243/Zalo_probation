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

@implementation HMContactAdapter

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        contactStore = [[CNContactStore alloc] init];
        contactSerialQueue = dispatch_queue_create("vn.com.hungmai.contactSerialQueue", DISPATCH_QUEUE_SERIAL);
        requestPermissionQueues = [NSMutableArray new];
        requestAllContactsQueues = [NSMutableArray new];
        mutableDelegate = [NSMutableArray new];
        
        isContactQueueRunning = NO;
        isRequestPermission = NO;
        
        cachePermissionError = nil;
        cachePermissionResult = NO;
        cacheContacts = nil;
    }
    
    return self;
}

#pragma mark - Static

+ (instancetype)shareInstance {
    static HMContactAdapter *shareInstance;
    static dispatch_once_t dispatch_once_queue;
    dispatch_once(&dispatch_once_queue, ^{
        shareInstance = [[self alloc]initPrivate];
    });
    
    return shareInstance;
}

#pragma mark - Public

- (void)addDelegate:(id<HMContactAdapterDelegate>)delegate {
    if (!delegate) {
        return;
    }
    
    NSAssert([delegate conformsToProtocol:@protocol(HMContactAdapterDelegate)], @"Can't add a delegate not implemented HMContactAdapterDelegate protocol");
    [mutableDelegate addObject:delegate];
}

- (void)requestPermissionInQueue:(dispatch_queue_t)queue
                        completion:(void (^)(BOOL, NSError *))completionBlock {
    NSAssert(contactSerialQueue, @"Can't request contact permission. Contact serial queue is not initilized");
    
    if (isRequestPermission) {
        dispatch_async(queue, ^{
            completionBlock(cachePermissionResult, cachePermissionError);
        });
        
        return;
    }
    
    HMContactPermissionQueueEntity *queueEntity = [[HMContactPermissionQueueEntity alloc] initWithQueue:queue permissionBlock:completionBlock];
    if (queueEntity) {
        [requestPermissionQueues addObject:queueEntity];
    }

    if (isContactQueueRunning) {
        NSLog(@"[HM] Request permission: queue is running");
        return;
    } else {
        isContactQueueRunning = YES;
    }
    
    dispatch_async(contactSerialQueue, ^{
        NSLog(@"[HM] Request permission: queue start");
        
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        __block BOOL result = NO;
        __block NSError *permissionError = nil;
        switch (status) {
                case CNAuthorizationStatusAuthorized:
                result = YES;
                break;
                case CNAuthorizationStatusNotDetermined:
                [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    result = granted;
                    permissionError = error;
                }];
                break;
                case CNAuthorizationStatusDenied: {
                    result = NO;
                    NSDictionary *dict = @{kErrorMessage: NSLocalizedString(@"User denied contact permission", nil),
                                           kErrorCode: @1,
                                           kErrorType:[NSNumber numberWithInteger:HMPermissionErrorTypeDenied]};
                    permissionError = [HMErrorFactory makeErrorWithFactoryType:HMErrorFactoryTypePermission withParamsDict:dict];
                    break;
                }
                
                case CNAuthorizationStatusRestricted: {
                    result = NO;
                    NSDictionary *dict = @{kErrorMessage: NSLocalizedString(@"User restricted contact permission", nil),
                                           kErrorCode: @2,
                                           kErrorType:[NSNumber numberWithInteger:HMPermissionErrorTypeRestricted]};
                    permissionError = [HMErrorFactory makeErrorWithFactoryType:HMErrorFactoryTypePermission withParamsDict:dict];
                    break;
                }
            default:
                break;
        }
        
        [requestPermissionQueues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[HMContactPermissionQueueEntity class]]) {
                HMContactPermissionQueueEntity *queueEntity = obj;
                dispatch_async(queueEntity.queue, ^{
                    NSLog(@"[HM] Request permission: queue return");
                    queueEntity.permissionBlock(result, permissionError);
                });
            }
        }];
        [requestPermissionQueues removeAllObjects];
        
        cachePermissionResult = result;
        cachePermissionError = permissionError;
        isRequestPermission = YES;
        isContactQueueRunning = NO;
    });
}

- (void)getAllContactsInQueue:(dispatch_queue_t)queue
                   modelClass:(Class<HMContactModel>)modelClass
                   completion:(void (^)(NSArray *, NSError *))completionBlock {
    NSAssert(contactSerialQueue, @"Can't get contacts. Contact serial queue is not initilized");
    
    [self requestPermissionInQueue:globalDefaultQueue completion:^(BOOL granted, NSError *error) {
        HMContactGettingQueueEntity *queueEntity = [[HMContactGettingQueueEntity alloc] initWithQueue:queue gettingBlock:completionBlock];
        if (queueEntity) {
            [requestAllContactsQueues addObject:queueEntity];
        }
        
        if (isContactQueueRunning) {
            NSLog(@"[HM] Request contacts: queue is running");
            return;
        } else {
            isContactQueueRunning = YES;
        }
        
        dispatch_async(contactSerialQueue, ^{
            NSLog(@"[HM] Request contacts: queue start");
            NSMutableArray *models = nil;
            NSError *getContactError = nil;
            if (error) {
                getContactError = error;
            } else {
                if (granted) {
                    models = [NSMutableArray new];
                    NSArray *keysToFetch = @[CNContactEmailAddressesKey,
                                             CNContactFamilyNameKey,
                                             CNContactGivenNameKey,
                                             CNContactPhoneNumbersKey,
                                             CNContactImageDataKey,
                                             CNContactThumbnailImageDataKey];
                    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
                    NSError *error;
                    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                        if (contact && (![self hasAlreadyData] || ![self containtContact:contact])) {
                            id model = [modelClass modelWithContact:contact];
                            [models addObject:model];
                        }
                    }];
                }
            }
            
            if ([self hasAlreadyData]) {
                [cacheContacts addObjectsFromArray:models];
            } else {
                cacheContacts = models;
            }
            
            
            [requestAllContactsQueues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[HMContactGettingQueueEntity class]]) {
                    HMContactGettingQueueEntity *queueEntity = obj;
                    dispatch_async(queueEntity.queue, ^{
                        NSLog(@"[HM] Request contacts: queue return");
                        queueEntity.gettingBlock(cacheContacts, getContactError);
                    });
                }
            }];
            [requestAllContactsQueues removeAllObjects];
            
            isContactQueueRunning = NO;
        });
    }];
}

- (void)getAllContactsSequenceInQueue:(dispatch_queue_t)queue
                           modelClass:(Class<HMContactModel>)modelClass
                        sequenceCount:(NSUInteger)sequenceCount
                             sequence:(void (^)(NSArray *))sequenceBlock
                           completion:(void (^)(NSError *))completionBlock {
    
    NSAssert(contactSerialQueue, @"Can't get contacts. Contact serial queue is not initilized");
    
    [self requestPermissionInQueue:globalDefaultQueue completion:^(BOOL granted, NSError *error) {
        HMContactSequenceQueueEntity *queueEntity = [[HMContactSequenceQueueEntity alloc] initWithQueue:queue
                                                                                               sequence:sequenceBlock
                                                                                               complete:completionBlock];
        if (queueEntity) {
            [requestAllContactsQueues addObject:queueEntity];
        }
        
        if (isContactQueueRunning) {
            NSLog(@"[HM] Request contacts: queue is running");
            return;
        } else {
            isContactQueueRunning = YES;
        }
        
        dispatch_async(contactSerialQueue, ^{
            NSLog(@"[HM] Request contacts: queue start");
            NSMutableArray *models = nil;
            NSError *getContactError = nil;
            __block NSMutableArray *tempModels = [NSMutableArray new];
            if (error) {
                getContactError = error;
            } else {
                if (granted) {
                    models = [NSMutableArray new];
                    
                    NSArray *keysToFetch = @[CNContactEmailAddressesKey,
                                             CNContactFamilyNameKey,
                                             CNContactGivenNameKey,
                                             CNContactPhoneNumbersKey,
                                             CNContactImageDataKey,
                                             CNContactThumbnailImageDataKey];
                    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
                    NSError *error;
                    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                        if (contact && (![self hasAlreadyData] || ![self containtContact:contact])) {
                            id model = [modelClass modelWithContact:contact];
                            [tempModels addObject:model];
                            [models addObject:model];
                            if (tempModels.count % sequenceCount == 0) {
                                [self transferDataWithModels:tempModels andError:getContactError];
                                tempModels = [NSMutableArray new];
                            }
                        }
                    }];
                }
            }
            
            if (tempModels.count > 0) {
                [self transferDataWithModels:tempModels andError:getContactError];
                tempModels = [NSMutableArray new];
            }
            
            if ([self hasAlreadyData]) {
                [cacheContacts addObjectsFromArray:models];
            } else {
                cacheContacts = models;
            }
            
            [requestAllContactsQueues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[HMContactSequenceQueueEntity class]]) {
                    HMContactSequenceQueueEntity *queueEntity = obj;
                    dispatch_async(queueEntity.queue, ^{
                        NSLog(@"[HM] Request contacts: queue return");
                        queueEntity.completeBlock(getContactError);
                    });
                }
            }];
            
            [requestAllContactsQueues removeAllObjects];
            
            isContactQueueRunning = NO;
        });
    }];
}

- (void)prepareDataWithObjectClass:(Class<HMCellObject>)objectClass
                         andModels:(NSArray *)models
                       groupObject:(BOOL)groupObject
                           inQueue:(dispatch_queue_t)queue
                        completion:(void (^)(NSArray *))completionBlock {
    
    NSAssert([objectClass conformsToProtocol:@protocol(HMCellObject)], @"You should pass a class implemented HMCellObject protocol");
    
    dispatch_async(queue ? queue : mainQueue, ^{
        if (groupObject) {
            NSDictionary *groupDict = [self groupModels:models];
            NSArray *data = [self makeCellContentWithDictionary:groupDict objectClass:objectClass];
            dispatch_async(mainQueue, ^{
                completionBlock(data);
            });
        }
    });
}

- (BOOL)isGrantedPermission {
    return isRequestPermission;
}

- (BOOL)hasAlreadyData {
    return cacheContacts.count > 0 ? YES : NO;
}

- (NSArray *)getAlreadyContacts {
    return cacheContacts;
}

- (BOOL)isStartedTimer {
    return isStartedTimer;
}

- (BOOL)startFrequentlyGetContactAfterMinute:(long)minute {
    [self stopFrequentlyGetContact];
    
    long second = minute * 60;
    requestContactTimer = [NSTimer scheduledTimerWithTimeInterval:second target:self selector:@selector(requestContactFrequently) userInfo:nil repeats:YES];
    isStartedTimer = YES;
    return requestContactTimer ? YES : NO;
}

- (BOOL)stopFrequentlyGetContact {
    isStartedTimer = NO;
    if (requestContactTimer) {
        [requestContactTimer invalidate];
        return YES;
    }
    return NO;
}

#pragma mark - Private

- (void)transferDataWithModels:(NSArray *)models andError:(NSError *)error {
    [requestAllContactsQueues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[HMContactSequenceQueueEntity class]]) {
            HMContactSequenceQueueEntity *queueEntity = obj;
            dispatch_async(queueEntity.queue, ^{
                queueEntity.sequenceBlock(models);
            });
        }
    }];
}

- (BOOL)containtContact:(CNContact *)contact {
    __block BOOL result = NO;
    [cacheContacts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[HMContactModel class]] && [((HMContactModel *)obj).identifier isEqualToString:contact.identifier]) {
            result = YES;
        }
    }];
    
    return result;
}

//Group contact with first character name
- (NSDictionary *)groupModels:(NSArray *)models{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [models enumerateObjectsUsingBlock:^(id<HMContactModel>  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSAssert([model conformsToProtocol:@protocol(HMContactModel)], @"You should pass a model implemented HMContactModel protocol");
        
        //Check params is valid
        if (!model || !dict) {
            return;
        }
        
        NSString *firstCharacter = [model groupName];
        NSMutableArray *groupContactArray = [dict objectForKey:firstCharacter];
        if (!groupContactArray) {
            groupContactArray = [NSMutableArray new];
            [dict setObject:groupContactArray forKey:firstCharacter];
        }
        [groupContactArray addObject:model];
    }];
    
    return dict;
}

- (NSArray *)makeCellContentWithDictionary:(NSDictionary *)groupCellDict
                                             objectClass:(Class<HMCellObject>)objectClass{
    NSMutableArray *cellContent = [NSMutableArray new];
    NSArray *allGroupKey = [groupCellDict allKeys]; //Get all characters section
    
    //Sort alphabet characters
    allGroupKey = [allGroupKey sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    
    [allGroupKey enumerateObjectsUsingBlock:^(NSString *  _Nonnull groupKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([groupKey isKindOfClass:[NSString class]]) { //warrant group key is a string
            [cellContent addObject:groupKey];
            NSMutableArray *groupContactArray = [groupCellDict objectForKey:groupKey];
            [groupContactArray enumerateObjectsUsingBlock:^(id _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                NSAssert([objectClass conformsToProtocol:@protocol(HMCellObject)], @"You should pass a class implemented HMCellObject protocol");
                id object = [objectClass objectWithModel:model];
                [cellContent addObject:object];
            }];
        }
    }];
    return cellContent;
}

- (void)requestContactFrequently {
    [self getAllContactsInQueue:nil modelClass:[HMContactModel class] completion:^(NSArray *contactModels, NSError *error) {
        [mutableDelegate enumerateObjectsUsingBlock:^(id<HMContactAdapterDelegate>  _Nonnull delegate, NSUInteger idx, BOOL * _Nonnull stop) {
            [delegate hmContactAdapter:self didReceiveContactsRequently:cacheContacts];
        }];
    }];
}

@end
