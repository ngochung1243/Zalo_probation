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
#import "ContactModel.h"

@interface ContactTableObject : NIDrawRectBlockCellObject

+ (instancetype)objectWithContact:(ContactModel *)contact;

@end

@interface ContactTableCell: NIDrawRectBlockCell
@end
