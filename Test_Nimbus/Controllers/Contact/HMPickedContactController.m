//
//  HMPickedContactController.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMPickedContactController.h"
#import "Constaint.h"
#import "Masonry.h"

#define ItemSpacing 5
#define ContentInset UIEdgeInsetsMake(0, 10, 0, 10)

@interface HMPickedContactController ()

@end

@implementation HMPickedContactController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = ItemSpacing;
    layout.itemSize = AvatarSmallSize;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.delegate = self;
    [self.view addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _pickModels = [NSMutableArray new];
    _modelDataSource = [[NIMutableCollectionViewModel alloc] initWithListArray:[NSMutableArray new] delegate:(id)[NICollectionViewCellFactory class]];
    
    _collectionView.dataSource = _modelDataSource;
}

#pragma mark - Handle Action

- (void)pickModel:(id)model {
    if (![_pickModels containsObject:model]) {
        [_pickModels addObject:model];
        NSArray *indexPaths = [_modelDataSource addObject:[HMContactCollectionObject objectWithModel:model]];
        [_collectionView insertItemsAtIndexPaths:indexPaths];
    }
}

- (void)unpickModel:(id)model {
    if ([_pickModels containsObject:model]) {
        NSUInteger index = [_pickModels indexOfObject:model];
        [_pickModels removeObject:model];
        NSArray *indexPaths = [_modelDataSource removeObjectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        [_collectionView deleteItemsAtIndexPaths:indexPaths];
    }
}

- (BOOL)isContainModel:(id)model {
    return [_pickModels containsObject:model];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (cell.alpha == 1) {
        cell.alpha = 0.5;
        id model = _pickModels[indexPath.row];
        if (_delegate && [_delegate respondsToSelector:@selector(hmPickedContactController:didSelectModel:)]) {
            [_delegate hmPickedContactController:self didSelectModel:model];
        }
    } else {
        cell.alpha = 1;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = 1;
}

@end
