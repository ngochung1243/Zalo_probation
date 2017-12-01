//
//  HMInviteContactController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMInviteContactController.h"
#import "HMContactViewController.h"
#import "Masonry.h"
#import "Constaint.h"
#import "HMAlertUtils.h"

#define ContactManager             [HMContactManager shareInstance]

#define ContactBarViewHeight        60
#define SearchBarHeight             45
#define TimeIntervalRequest         1
#define PickerViewPadding           UIEdgeInsetsMake(0, 10, 0, 10)

@implementation HMInviteContactController

- (void)viewDidLoad {
    [super viewDidLoad];
    _contacts = [NSMutableArray new];
    self.view.backgroundColor = [UIColor colorWithRed:205.0/255 green:205.0/255 blue:210.0/255 alpha:1];
    [ContactManager addDelegate:self];
    
    _headerView = [[UIView alloc] init];
    _headerView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_headerView];
    [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.mas_equalTo(0);
    }];
    
    _searchBarView = [[HMTransparentSearchBar alloc] init];
    _searchBarView.backgroundColor = UIColor.clearColor;
    _searchBarView.delegate = self;
    [self.view addSubview:_searchBarView];
    [_searchBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headerView.mas_bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.mas_equalTo(SearchBarHeight);
    }];
    
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_contentView];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_searchBarView.mas_bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    _contactVC = [[HMContactViewController alloc] init];
    _contactVC.delegate = self;
    [self addChildViewController:_contactVC];
    [_contentView addSubview:_contactVC.view];
    [_contactVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_contentView);
    }];
    
    _pickedContactVC = [[HMPickedContactController alloc] init];
    _pickedContactVC.delegate = self;
    [self addChildViewController:_pickedContactVC];
    [_headerView addSubview:_pickedContactVC.view];
    [_pickedContactVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_headerView).insets(PickerViewPadding);
    }];
    
    [self loadContactWithCompletion:nil];
}

- (void)loadContactWithCompletion:(void(^)(BOOL))completionBlock {
    if ([ContactManager hasAlreadyData]) {
        [_contacts addObjectsFromArray:[ContactManager getAlreadyContacts]];
        [_contactVC setData:_contacts];
        if (completionBlock) {
            completionBlock(YES);
        }
        
        return;
    }
    
    [ContactManager requestPermissionInQueue:mainQueue completion:^(BOOL granted, NSError *error) {
        if (granted) {
//            [self getAllContactsWithCompletion:completionBlock];
            [self getAllContactsSequence];
            return;
        }
        
        if (error && [error isKindOfClass:[HMPermissionError class]]) {
            HMPermissionError *permissionError = (HMPermissionError *)error;
            switch (permissionError.errorType) {
                case HMPermissionErrorTypeDenied: {
                    [HMAlertUtils showSettingAlertInController:self activeBlock:^{
                        if (@available(iOS 10.0, *)) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                        } else {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }
                    
                    } passiveBlock:nil];
                    break;
                }
                case HMPermissionErrorTypeRestricted:
                    break;
                case HMPermissionErrorTypeUnknown:
                    break;
                case HMPermissionErrorTypeNotDetermined:
                    break;
                default:
                    break;
            }
            
            completionBlock(NO);
        }
    }];
}

- (void)getAllContactsWithCompletion:(void(^)(BOOL))completionBlock {
    [_contacts removeAllObjects];
    [ContactManager getAllContactsInQueue:mainQueue modelClass:[HMContactModel class] completion:^(NSArray *contactModels, NSError *error) {
        if (!error) {
            [_contacts addObjectsFromArray:contactModels];
            [_contactVC setData:contactModels];
            completionBlock(YES);
        } else {
            //Handle error;
            completionBlock(NO);
        }
    }];
}

- (void)getAllContactsSequence {
    [ContactManager getAllContactsSequenceInQueue:mainQueue
                                       modelClass:[HMContactModel class]
                                    sequenceCount:50
                                         sequence:^(NSArray *contactModels) {
        [_contactVC addData:contactModels];
    } completion:^(NSError *error) {
        return;
    }];
}

- (NSArray *)filterModelsWithString:(NSString *)string {
    if (!string || [string isEqualToString:@""]) {
        return _contacts;
    }
    
    NSIndexSet *indexSet = [_contacts indexesOfObjectsPassingTest:^BOOL(HMContactModel * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([contact isKindOfClass:[HMContactModel class]]) {
            return [contact.fullName containsString:string];
        }
        return NO;
    }];
    return [_contacts objectsAtIndexes:indexSet];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    dispatch_async(globalDefaultQueue, ^{
        NSArray *filterModels = [self filterModelsWithString:searchText];
        [_contactVC setData:filterModels];
    });
}

#pragma mark - HMContactViewDelegate
- (void)hmContactViewController:(HMContactViewController *)contactVC didSelectModel:(id)model {
    if (_pickedContactVC.pickModels.count == 0) {
        [_headerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(ContactBarViewHeight);
        }];
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    [_pickedContactVC pickModel:model];
}

- (void)hmContactViewController:(HMContactViewController *)contactVC didDeselectModel:(id)model {
    [_pickedContactVC unpickModel:model];
    if (_pickedContactVC.pickModels.count == 0) {
        [_headerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (BOOL)hmContactViewController:(HMContactViewController *)contactVC checkSelectedModel:(id)model {
    return [_pickedContactVC isContainModel:model];
}

#pragma mark - HMPickedContactDelegate
- (void)hmPickedContactController:(HMPickedContactController *)pickedController didSelectModel:(id)model {
    [_contactVC scrollToModel:model];
}

#pragma mark - HMContactAdapterDelegate
- (void)hmContactManager:(HMContactManager *)manager didReceiveContactsRequently:(NSArray *)contacts {
    [_contacts removeAllObjects];
    [_contacts addObjectsFromArray:contacts];
    [_contactVC setData:_contacts];
}

@end
