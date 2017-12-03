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
#import "HMCTTableObject.h"

@interface HMCTCollectionObject : NSObject <NICollectionViewCellObject, HMCellObject>
@property(strong, nonatomic) id model;
@end

@interface HMCTCollectionCell: UICollectionViewCell <NICollectionViewCell>

@property(strong, nonatomic) UIImageView *avatarImageView;

@end
