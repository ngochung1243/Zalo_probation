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

@implementation HMContactAdapter

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        contactStore = [[CNContactStore alloc] init];
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

- (void)requestPermissionInQueue:(dispatch_queue_t)queue
                        completion:(void (^)(BOOL, NSError *))completionBlock {
    dispatch_async(queue ? queue : mainQueue, ^{
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
        
        dispatch_async(mainQueue, ^{
            completionBlock(result, permissionError);
        });
    });
}

- (void)getAllContactsInQueue:(dispatch_queue_t)queue
                   modelClass:(Class<HMContactModel>)modelClass
                   completion:(void (^)(NSArray *, NSError *))completionBlock {
    [self requestPermissionInQueue:queue completion:^(BOOL granted, NSError *error) {
        if (error) {
            completionBlock(nil, error);
            return;
        }
        
        NSMutableArray *models = [NSMutableArray new];
        
        if (granted) {
            NSArray *keysToFetch = @[CNContactEmailAddressesKey,
                                     CNContactFamilyNameKey,
                                     CNContactGivenNameKey,
                                     CNContactPhoneNumbersKey,
                                     CNContactImageDataKey,
                                     CNContactThumbnailImageDataKey];
            CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
            NSError *error;
            [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                if (contact) {
                    id model = [modelClass modelWithContact:contact];
                    [models addObject:model];
                }
            }];
            
            completionBlock(models, error);
        }
        
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
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusAuthorized) {
        return YES;
    }
    return NO;
}

#pragma mark - Private

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

@end
