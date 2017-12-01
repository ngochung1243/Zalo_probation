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
#import "HMContactQueueEntity.h"

#define DefaultGetCTTimeInterval           120

@implementation HMContactManager

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        contactStore = [[CNContactStore alloc] init];
        contactSerialQueue = dispatch_queue_create("vn.com.hungmai.contactSerialQueue", DISPATCH_QUEUE_SERIAL);
        mutableDelegate = [NSMutableArray new];
        
        isRequestPermission = NO;
        isGetedContacts = NO;
        updateTimeInterval = DefaultGetCTTimeInterval;
        
        cachePermissionError = nil;
        cachePermissionResult = NO;
        cacheContacts = [NSMutableArray new];
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

- (void)addDelegate:(id<HMContactManagerDelegate>)delegate {
    if (!delegate) {
        return;
    }
    
    NSAssert([delegate conformsToProtocol:@protocol(HMContactManagerDelegate)], @"Can't add a delegate not implemented HMContactAdapterDelegate protocol");
    [mutableDelegate addObject:delegate];
}

- (void)requestPermissionInQueue:(dispatch_queue_t)queue
                      completion:(void (^)(BOOL, NSError *))completionBlock {
    
    NSAssert(contactSerialQueue, @"Can't request contact permission. Contact serial queue is not initilized");
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];
    
    dispatch_async(contactSerialQueue, ^{
        if (isRequestPermission) { //If requested permission before, using the cached result
            dispatch_async(returnQueue, ^{
                NSLog(@"[HM] Request permission: queue quick return");
                if (completionBlock) {
                    completionBlock(cachePermissionResult, cachePermissionError);
                }
            });
            
            return;
        }
        
        NSLog(@"[HM] Request permission: queue start");
        
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        __block BOOL result = NO;
        __block NSError *permissionError = nil;
        switch (status) {
            case CNAuthorizationStatusAuthorized:
                result = YES;
                break;
            case CNAuthorizationStatusNotDetermined: {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    result = granted;
                    permissionError = error;
                    dispatch_semaphore_signal(semaphore);
                }];
                dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC))); //Wait the request completely
                break;
            }
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
        
        cachePermissionResult = result;
        cachePermissionError = permissionError;
        isRequestPermission = YES;
        
        dispatch_async(returnQueue, ^{
            NSLog(@"[HM] Request permission: queue return");
            if (completionBlock) {
                completionBlock(cachePermissionResult, cachePermissionError);
            }
        });
    });
}

- (void)getAllContactsWithReturnQueue:(dispatch_queue_t)queue
                   modelClass:(Class<HMContactModel>)modelClass
                   completion:(void (^)(NSArray *, NSError *))completionBlock {
    
    NSAssert(contactSerialQueue, @"Can't get contacts. Contact serial queue is not initilized");
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];
    
    if (isRequestPermission && cachePermissionResult) { //If granted permission before, request all contacts
        [self allowGetAllContactsWithReturnQueue:queue
                              modelClass:modelClass
                              completion:completionBlock];
        return;
    }
    
    //Request permission before requesting all contacts
    __weak __typeof__(self) weakSelf = self;
    [self requestPermissionInQueue:globalDefaultQueue completion:^(BOOL granted, NSError *error) {
        if (error) {
            if (completionBlock) {
                completionBlock(nil, error);
            }
            
            return;
        }
        
        [weakSelf allowGetAllContactsWithReturnQueue:returnQueue
                                  modelClass:modelClass
                                  completion:completionBlock];
    }];
}

- (void)getAllContactsSeqWithReturnQueue:(dispatch_queue_t)queue
                           modelClass:(Class<HMContactModel>)modelClass
                        sequenceCount:(NSUInteger)sequenceCount
                             sequence:(void (^)(NSArray *))sequenceBlock
                           completion:(void (^)(NSError *))completionBlock {
    
    NSAssert(contactSerialQueue, @"Can't get contacts. Contact serial queue is not initilized");
    
    dispatch_queue_t returnQueue = [self getReturnQueueWithQueue:queue];

    if (isRequestPermission && cachePermissionResult) { //If granted permission before, request all contacts with sequence result
        [self allowGetAllContactsSeqWithReturnQueue:returnQueue
                                      modelClass:modelClass
                                   sequenceCount:sequenceCount
                                        sequence:sequenceBlock
                                      completion:completionBlock];
        return;
    }
    
    //Request permission before requesting all contacts
    __weak __typeof__(self) weakSelf = self;
    [self requestPermissionInQueue:globalDefaultQueue completion:^(BOOL granted, NSError *error) {
        if (error) {
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        [weakSelf allowGetAllContactsSeqWithReturnQueue:returnQueue
                                      modelClass:modelClass
                                   sequenceCount:sequenceCount
                                        sequence:sequenceBlock
                                      completion:completionBlock];
    }];
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

- (void)setUpdateTimeIntervalWithSecond:(double)second {
    if (second >= 0) {
        updateTimeInterval = second;
    }
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

//Get all contact when passing contact permission
- (void)allowGetAllContactsWithReturnQueue:(dispatch_queue_t)queue
                        modelClass:(Class<HMContactModel>)modelClass
                        completion:(void (^)(NSArray *, NSError *))completionBlock {
    
    dispatch_async(contactSerialQueue, ^{ //Get all contacts in serial queue for multiple requests purpose
        if (isGetedContacts && ![self checkCacheContactsExpireTime]) { //If got all contacts before and the past request time is not expire, return the cached contacts
            dispatch_async(queue, ^{
                NSLog(@"[HM] Request contacts: queue quick return");
                if (completionBlock) {
                    completionBlock(cacheContacts, nil);
                }
            });
            
            return;
        }
        
        isGetedContacts = NO;
        [cacheContacts removeAllObjects];
        
        NSLog(@"[HM] Request contacts: queue start");
        
        NSMutableArray *models = [NSMutableArray new];
        
        NSArray *keysToFetch = @[CNContactEmailAddressesKey,
                                 CNContactFamilyNameKey,
                                 CNContactGivenNameKey,
                                 CNContactPhoneNumbersKey,
                                 CNContactImageDataKey,
                                 CNContactThumbnailImageDataKey];
        
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        NSError *error;
        
        [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            if (contact && (![self hasAlreadyData] || ![self containtContact:contact])) { //If the contact was cached, skip it
                id model = [modelClass modelWithContact:contact];
                [models addObject:model];
            }
        }];
        
        [cacheContacts addObjectsFromArray:models];
        
        dispatch_async(queue, ^{ //Return the result with the completion block in the queue user want to handle
            NSLog(@"[HM] Request contacts: queue return");
            if (completionBlock) {
                completionBlock(cacheContacts, nil);
            }
        });
        
        isGetedContacts = YES;
        lastUpdate = [NSDate date]; //Update the current request expire time
    });
}

//Get all contact when passing contact permission
- (void)allowGetAllContactsSeqWithReturnQueue:(dispatch_queue_t)queue
                                modelClass:(Class<HMContactModel>)modelClass
                             sequenceCount:(NSUInteger)sequenceCount
                                  sequence:(void (^)(NSArray *))sequenceBlock
                                completion:(void (^)(NSError *))completionBlock {
    
    dispatch_async(contactSerialQueue, ^{ //Get all contacts in serial queue for multiple requests purpose
        if (isGetedContacts && ![self checkCacheContactsExpireTime]) { //If got all contacts before and the past request time is not expire, return the cached contacts
            dispatch_async(queue, ^{
                NSLog(@"[HM] Request contacts sequence: queue quick return");
                if (sequenceBlock) {
                    sequenceBlock(cacheContacts);
                }
                
                if (completionBlock) {
                    completionBlock(nil);
                }
            });
            
            return;
        }
        
        isGetedContacts = NO;
        [cacheContacts removeAllObjects];
        
        NSLog(@"[HM] Request contacts sequence: queue start");
        NSMutableArray *models = [NSMutableArray new];
        NSMutableArray *tempModels = [NSMutableArray new];
        
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
            if (contact && (![self hasAlreadyData] || ![self containtContact:contact])) { //If the contact was cached, skip it
                id model = [modelClass modelWithContact:contact];
                [tempModels addObject:model];
                [models addObject:model];
                if (tempModels.count % sequenceCount == 0) { //When got enough models user wanted, return the models block to user
                    NSArray *tempModelCP = [tempModels copy];
                    dispatch_async(queue, ^{
                        if (sequenceBlock) {
                            sequenceBlock(tempModelCP);
                        }
                    });
                    
                    [tempModels removeAllObjects];
                }
            }
        }];
        
        if (tempModels.count != 0) { //If the last models block still have models, return them to user
            NSArray *tempModelCP = [tempModels copy];
            dispatch_async(queue, ^{
                if (sequenceBlock) {
                    sequenceBlock(tempModelCP);
                }
            });
            
            [tempModels removeAllObjects];
        }
        
        [cacheContacts addObjectsFromArray:models];
        
        dispatch_async(queue, ^{ //Return the result with the completion block in the queue user want to handle
            NSLog(@"[HM] Request contacts sequence: queue return");
            completionBlock(nil);
        });
        
        isGetedContacts = YES;
        lastUpdate = [NSDate date]; //Update the current request expire time
    });
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

- (void)requestContactFrequently {
    [self getAllContactsWithReturnQueue:nil modelClass:[HMContactModel class] completion:^(NSArray *contactModels, NSError *error) {
        [mutableDelegate enumerateObjectsUsingBlock:^(id<HMContactManagerDelegate>  _Nonnull delegate, NSUInteger idx, BOOL * _Nonnull stop) {
            [delegate hmContactManager:self didReceiveContactsRequently:cacheContacts];
        }];
    }];
}

- (BOOL)checkCacheContactsExpireTime {
    NSTimeInterval interval = [lastUpdate timeIntervalSinceNow];
    return interval < updateTimeInterval ? NO : YES;
}

- (dispatch_queue_t)getReturnQueueWithQueue:(dispatch_queue_t)queue {
    return queue ? queue : mainQueue;
}

@end

