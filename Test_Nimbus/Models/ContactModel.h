//
//  ContactModel.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseModel.h"
#import <Contacts/Contacts.h>

@interface ContactModel : BaseModel

@property(strong, nonatomic) NSString *firstName;
@property(strong, nonatomic) NSString *lastName;
@property(strong, nonatomic) UIImage *imageData;
@property(getter=fullname, readonly) NSString *fullName;

- (instancetype)initWithCNContact:(CNContact *)contact;

@end
