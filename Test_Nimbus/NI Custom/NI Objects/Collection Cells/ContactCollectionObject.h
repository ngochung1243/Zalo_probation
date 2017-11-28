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
#import "ContactModel.h"
#import "Constaint.h"

@interface ContactCollectionObject : NSObject <NICollectionViewCellObject>

@property(strong, nonatomic) ContactModel *contact;

+ (instancetype)objectWithContact:(ContactModel *)contact;

@end

@interface ContactCollectionCell: UICollectionViewCell <NICollectionViewCell>

@property(strong, nonatomic) UIImageView *avatarImageView;

@end
