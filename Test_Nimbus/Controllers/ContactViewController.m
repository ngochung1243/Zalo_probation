//
//  ContactViewController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ContactViewController.h"
#import "NIInterapp.h"
#import "DGActivityIndicatorView.h"
#import "CNContact+Utils.h"
#import "Masonry.h"
#import "UIImage+Utils.h"
#import "ContactModel.h"

#define ContactBarViewHeight 60
#define SearchBarHeight 45
#define TableCellHeight 60

@interface ContactViewController () <ContactBarViewDelegate> {
    DGActivityIndicatorView *indicatorView;
}

@end

@implementation ContactViewController

#pragma mark - View life circle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Chọn bạn";
        self.view.backgroundColor = [UIColor colorWithRed:205.0/255 green:205.0/255 blue:210.0/255 alpha:1];
        _contacts = [NSMutableDictionary new];
        _actions = [[NITableViewActions alloc] initWithTarget:self];
        
        //Init and constraint subview
        indicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulse tintColor:UIColor.blueColor];
        indicatorView.frame = CGRectMake(0, 0, 32, 32);
        indicatorView.center = self.view.center;
        [self.tableView addSubview:indicatorView];
        
        _contactBarView = [[ContactBarView alloc] init];
        _contactBarView.barViewDelegate = self;
        [self.view addSubview:_contactBarView];
        [_contactBarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.mas_equalTo(0);
        }];
        
        _searchBar = [[TransparentSearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.backgroundColor = UIColor.clearColor;
        [self.view addSubview:_searchBar];
        [_searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_contactBarView.mas_bottom);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.mas_equalTo(SearchBarHeight);
        }];
        
        _tableView = [[UITableView alloc] init];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.allowsMultipleSelectionDuringEditing = YES;
        _tableView.allowsMultipleSelection = YES;
        _tableView.rowHeight = TableCellHeight;
        _tableView.tableFooterView = [UIView new];
        [_tableView setEditing:YES];
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_searchBar.mas_bottom);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.bottom.equalTo(self.view);
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [indicatorView startAnimating];
    
    //Get contact in background thread
    [self performSelectorInBackground:@selector(loadContact) withObject:nil];
}

#pragma mark - Contact implement

- (void)loadContact {
    CNContactStore *addressBook = [[CNContactStore alloc] init];
    NSArray *keysToFetch = @[CNContactEmailAddressesKey,
                             CNContactFamilyNameKey,
                             CNContactGivenNameKey,
                             CNContactPhoneNumbersKey,
                             CNContactImageDataKey,
                             CNContactThumbnailImageDataKey];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    [addressBook enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        if (contact) {
            ContactModel *contactModel = [[ContactModel alloc] initWithCNContact:contact];
            [self groupContact:contactModel withDictionary:_contacts];
        }
    }];
    //Prepare data for cells and display
    [self displayData:_contacts];
}

//Group contact with first character name
- (void)groupContact:(ContactModel *)contact withDictionary:(NSMutableDictionary *)dict{
    //Check params is valid
    if (!contact || !dict) {
        return;
    }
    
    NSString *fullName = contact.fullName;
    NSString *firstCharacter = fullName.length >= 1 ? [fullName substringWithRange:NSMakeRange(0, 1)] : @"";
    NSMutableArray *groupContactArray = [dict objectForKey:firstCharacter];
    if (!groupContactArray) {
        groupContactArray = [NSMutableArray new];
        [dict setObject:groupContactArray forKey:firstCharacter];
    }
    [groupContactArray addObject:contact];
}

//Prepare data for NITableViewModel
- (NSArray *)makeCellContentArrayWithGroupCellDictionary:(NSMutableDictionary *)groupCellDict {
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
            [groupContactArray enumerateObjectsUsingBlock:^(ContactModel *  _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([contact isKindOfClass:[ContactModel class]]) { //warrant contact is a contact model
                    id object = [self makeActionWithContact:contact];
                    NSAssert([object isKindOfClass:[NICellObject class]], @"Need to add an instance subclass of UICellObject for content of Table View");
                    [cellContent addObject:object];
                }
            }];
        }
    }];
    return cellContent;
}

- (void)displayData:(NSMutableDictionary *)groupCellDict {
    NSArray *cellContent = [self makeCellContentArrayWithGroupCellDictionary:groupCellDict];
    _modelDataSource = [[ContactTableViewModel alloc] initWithSectionedArray:cellContent delegate:(id)[ContactModelDelegate class]];
    _modelDataSource.pickContacts = _contactBarView.pickContacts;
    [_modelDataSource setSectionIndexType:NITableViewModelSectionIndexDynamic showsSearch:YES showsSummary:YES];
    
    //Render table view in main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicatorView stopAnimating];
        _tableView.dataSource = _modelDataSource;
        _tableView.delegate = [_actions forwardingTo:self];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_tableView reloadData];
    });
}

#pragma mark - Search Action

- (NSMutableDictionary *)filterContactWithSearchString:(NSString *)searchString {
    NSArray *allContacts = [_contacts allValues];
    NSMutableDictionary *filterContactsDict = [NSMutableDictionary new];
    if (!searchString || [searchString isEqualToString:@""]) {
        filterContactsDict = _contacts;
    } else {
        [allContacts enumerateObjectsUsingBlock:^(NSArray*  _Nonnull groupArray, NSUInteger idx, BOOL * _Nonnull stop) {
            [groupArray enumerateObjectsUsingBlock:^(ContactModel*  _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([contact.fullName containsString:searchString]) {
                    [self groupContact:contact withDictionary:filterContactsDict];
                }
            }];;
        }];
    }
    
    return filterContactsDict;
}

#pragma mark - Support Funtion

//Make NIObjectAction for each cell
- (id)makeActionWithContact:(ContactModel *)contact {
    return [_actions attachToObject:[ContactTableObject objectWithContact:contact] tapBlock:^BOOL(ContactTableObject* object, id target, NSIndexPath *indexPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.isSelected) { //Add contact to target array and show contact bar view if need
            if (_contactBarView.pickContacts.count == 0) {
                [_contactBarView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(ContactBarViewHeight);
                }];
                [UIView animateWithDuration:0.2 animations:^{
                    [self.view layoutIfNeeded];
                }];
            }
            [_contactBarView pickContact:object.object];
        } else { //Remove contact from target array and hide contact bar view if need
            [_contactBarView unpickContact:object.object];
            if (_contactBarView.pickContacts.count == 0) {
                [_contactBarView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(0);
                }];
                [UIView animateWithDuration:0.2 animations:^{
                    [self.view layoutIfNeeded];
                }];
            }
        }
        
        return NO;
    }];
}

#pragma mark - DELEGATE
#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *filterContactsDict = [self filterContactWithSearchString:searchText];
        [self displayData:filterContactsDict];
    });
}

#pragma mark - ContactBarViewDelegate
- (void)contactBarView:(ContactBarView *)contactBarView didSelectContact:(ContactModel *)contact {
    NSIndexPath *indexPath = [_modelDataSource indexPathWithObjectValue:contact];
    if (indexPath) {
        [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

@end

#pragma mark - Custom Object

@implementation ContactModelDelegate

//Allow data source can edit
+ (BOOL)tableViewModel:(NIMutableTableViewModel *)tableViewModel canEditObject:(id)object atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    return YES;
}

@end

@implementation ContactTableViewModel

//Check targeted contacts when filtering by search
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    ContactTableObject *object = [self objectAtIndexPath:indexPath];
    if (_pickContacts) {
        if ([_pickContacts containsObject:object.object]) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    return cell;
}

@end
