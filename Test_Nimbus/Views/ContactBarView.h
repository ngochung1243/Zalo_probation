//
//  ContactBarView.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NimbusModels.h"
#import "NimbusCollections.h"
#import <Contacts/Contacts.h>
#import "ContactCollectionObject.h"
#import "ContactModel.h"
#import "ContactTableObject.h"

@class ContactBarView;

@protocol ContactBarViewDelegate <NSObject>
- (void)contactBarView:(ContactBarView *)contactBarView didSelectContact:(ContactModel *)contact;
@end

@interface ContactBarView : UICollectionView <UICollectionViewDelegate>

@property(strong, nonatomic) NSMutableArray *pickContacts;
@property(strong, nonatomic) NICollectionViewActions *actions;
@property(strong, nonatomic) NIMutableCollectionViewModel *models;
@property(weak, nonatomic) id<ContactBarViewDelegate> barViewDelegate;

- (void)pickContact:(ContactModel *)contact;
- (void)unpickContact:(ContactModel *)contact;

@end
