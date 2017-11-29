//
//  HMPickedContactController.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/29/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NimbusCollections.h"
#import "HMContactCollectionObject.h"

@class HMPickedContactController;

@protocol HMPickedContactDelegate <NSObject>
- (void)hmPickedContactController:(HMPickedContactController *)pickedController didSelectModel:(id)model;
@end

@interface HMPickedContactController : UIViewController <UICollectionViewDelegate>

@property(strong, nonatomic) UICollectionView *collectionView;

@property(strong, nonatomic) NSMutableArray *pickModels;
@property(strong, nonatomic) NIMutableCollectionViewModel *modelDataSource;
@property(weak, nonatomic) id<HMPickedContactDelegate> delegate;

- (void)pickModel:(id)model;
- (void)unpickModel:(id)model;
- (BOOL)isContainModel:(id)model;

@end
