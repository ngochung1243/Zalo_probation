//
//  ContactCollectionObject.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NimbusCollections.h"
#import <Contacts/Contacts.h>
#import "HMContactModel.h"
#import "Constaint.h"

@interface HMContactCollectionObject : NSObject <NICollectionViewCellObject>

@property(strong, nonatomic) HMContactModel *contact;

+ (instancetype)objectWithContact:(HMContactModel *)contact;

@end

@interface HMContactCollectionCell: UICollectionViewCell <NICollectionViewCell>

@property(strong, nonatomic) UIImageView *avatarImageView;

@end
