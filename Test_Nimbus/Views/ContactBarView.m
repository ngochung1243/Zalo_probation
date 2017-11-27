//
//  ContactBarView.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ContactBarView.h"

@implementation ContactBarView

#define ItemSpacing 5
#define ContentInset UIEdgeInsetsMake(0, 10, 0, 10)

-(instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = ItemSpacing;
    layout.itemSize = AvatarSmallSize;
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.contentInset = ContentInset;
        
        _pickContacts = [NSMutableArray new];
        _actions = [[NICollectionViewActions alloc] initWithTarget:self];
        _models = [[NIMutableCollectionViewModel alloc] initWithListArray:[NSMutableArray new] delegate:(id)[NICollectionViewCellFactory class]];
        self.dataSource = _models;
        self.delegate = self;
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

#pragma mark - Bar Action
- (void)pickContact:(ContactModel *)contact {
    if (![_pickContacts containsObject:contact]) {
        [_pickContacts addObject:contact];
        NSArray *indexPaths = [_models addObject:[ContactCollectionObject objectWithContact:contact]];
        [self insertItemsAtIndexPaths:indexPaths ];
    }
}

- (void)unpickContact:(ContactModel *)contact {
    if ([_pickContacts containsObject:contact]) {
        NSUInteger index = [_pickContacts indexOfObject:contact];
        [_pickContacts removeObject:contact];
        NSArray *indexPaths = [_models removeObjectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        [self deleteItemsAtIndexPaths:indexPaths];
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    if (cell.alpha == 1) {
        cell.alpha = 0.5;
        ContactModel *contact = _pickContacts[indexPath.row];
        if (_barViewDelegate && [_barViewDelegate respondsToSelector:@selector(contactBarView:didSelectContact:)]) {
            [_barViewDelegate contactBarView:self didSelectContact:contact];
        }
    } else {
        cell.alpha = 1;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    cell.alpha = 1;
}

@end
