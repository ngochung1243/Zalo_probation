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
    [ContactManager addDelegate:self];
    
    self.title = NSLocalizedString(@"Choose friends", nil);
    self.view.backgroundColor = [UIColor colorWithRed:205.0/255 green:205.0/255 blue:210.0/255 alpha:1];
    
    //Layout subviews
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
    
    //Load data
    [self loadContactWithCompletion:nil];
}

- (void)setupNavigationBar {
    
}

//Load all contacts
- (void)loadContactWithCompletion:(void(^)(BOOL))completionBlock {
    
    __weak __typeof__(self) weakSelf = self;
    [ContactManager requestPermissionInQueue:mainQueue completion:^(BOOL granted, NSError *error) { //Request permission before
        if (granted) {
//            [weakSelf getAllContactsWithCompletion:completionBlock]; //Request all contacts
            [weakSelf getAllContactsSeqWithSegCount:50 completion:completionBlock];
            return;
        }
        
        if (error && [error isKindOfClass:[HMPermissionError class]]) { //If request permission error, check the error type and handle it
            HMPermissionError *permissionError = (HMPermissionError *)error;
            switch (permissionError.errorType) {
                case HMPermissionErrorTypeDenied: { //If user denied the permission, show apps setting
                    [HMAlertUtils showSettingAlertInController:self activeBlock:^{
                        if (@available(iOS 10.0, *)) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                                               options:@{}
                                                     completionHandler:nil];
                        } else {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }
                    
                    } passiveBlock:nil];
                    break;
                }
                default:
                    break;
            }
            
            completionBlock(NO);
        }
    }];
}

//Get all contacts of device
- (void)getAllContactsWithCompletion:(void(^)(BOOL))completionBlock {
    [_contacts removeAllObjects];
    
    __weak __typeof__(self) weakSelf = self;
    [ContactManager getAllContactsWithReturnQueue:mainQueue modelClass:[HMContactModel class] completion:^(NSArray *contactModels, NSError *error) {
        if (!error) { //If got all contacts, put them to contact view controller to handle them
            [weakSelf.contacts addObjectsFromArray:contactModels];
            [weakSelf.contactVC setData:contactModels];
            if (completionBlock) {
                completionBlock(YES);
            }
        } else { //Otherwise, return NO result
            if (completionBlock) {
                //Handle error;
                completionBlock(NO);
            }
        }
    }];
}

//Get all contacts of device with sequence block models
- (void)getAllContactsSeqWithSegCount:(NSUInteger)seqCount completion:(void(^)(BOOL))completionBlock {
    __weak __typeof__(self) weakSelf = self;
    [ContactManager getAllContactsSeqWithReturnQueue:mainQueue
                                       modelClass:[HMContactModel class]
                                    sequenceCount:seqCount
                                         sequence:^(NSArray *contactModels) { //When received the seq block with models, put them to contact view controller to handle them
                                     
        [weakSelf.contacts addObjectsFromArray:contactModels];
        [weakSelf.contactVC addData:contactModels];
                                             
    } completion:^(NSError *error) { //When received the completion block, check the error and return YES if no error happened
        if (completionBlock) {
            completionBlock(error ? NO : YES);
        }
    }];
}

#pragma mark - Support Func

//Get models having full name mapping search string
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
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(globalDefaultQueue, ^{
        NSArray *filterModels = [self filterModelsWithString:searchText];
        [weakSelf.contactVC setData:filterModels];
    });
}

#pragma mark - HMContactVCDelegate

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

#pragma mark - HMContactManagerDelegate

- (void)hmContactManager:(HMContactManager *)manager didReceiveContactsRequently:(NSArray *)contacts {
    [_contacts removeAllObjects];
    [_contacts addObjectsFromArray:contacts];
    [_contactVC setData:_contacts];
}

@end
