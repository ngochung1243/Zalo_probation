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
    
    
//    dispatch_async(globalDefaultQueue, ^{
//        for (int i = 0; i < 100; i ++) {
//            [self loadContactWithCompletion:^(BOOL result) {
//                NSLog(@"Default queue: %d", i);
//            }];
//        }
//    });
//    
//    dispatch_async(globalHighQueue, ^{
//        for (int i = 0; i < 100; i ++) {
//            [ContactManager requestPermissionWithBlock:^(BOOL granted, NSError *error) {
//                NSLog(@"High queue: %d", i);
//            } inQueue:globalHighQueue];
//        }
//    });
//    
//    dispatch_async(globalBackgroundQueue, ^{
//        for (int i = 0; i < 100; i ++) {
//            [ContactManager requestPermissionWithBlock:^(BOOL granted, NSError *error) {
//                NSLog(@"Background queue: %d", i);
//            } inQueue:globalBackgroundQueue];
//        }
//    });
}

//Load all contacts
- (void)loadContactWithCompletion:(void(^)(BOOL))completionBlock {
    __weak __typeof__(self) weakSelf = self;
    [ContactManager getAllContactsWithBlock:^(NSArray *models, NSError *error) {
        if (!error) { //If got all contacts, put them to contact view controller to handle them
            [weakSelf.contacts addObjectsFromArray:models];
            [weakSelf.contactVC setData:models];
            if (completionBlock) {
                completionBlock(YES);
            }
        } else { //Otherwise, return NO result
            if (completionBlock) {
                //Handle error;
                completionBlock(NO);
            }
        }
    } inQueue:nil];
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

@end
