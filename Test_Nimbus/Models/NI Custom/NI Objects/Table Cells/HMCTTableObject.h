//
//  ContactTableObject.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NimbusModels.h"
#import <Contacts/Contacts.h>
#import "HMContactModel.h"

@protocol HMCellObject <NSObject>
+ (instancetype)objectWithModel:(id)model;
- (id)getModel;
- (NSComparisonResult)compare:(id)object;
@end

@interface HMCTTableObject : NICellObject <HMCellObject>
@property(strong, nonatomic) id model;
@end

@interface HMCTTableCell: UITableViewCell<NICell>

@property(strong, nonatomic) UIImageView *avatarView;
@property(strong, nonatomic) UILabel *nameLabel;
@end
