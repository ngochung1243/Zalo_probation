//
//  ContactModel.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/27/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMBaseModel.h"
#import <Contacts/Contacts.h>

@protocol HMContactModel <NSObject>

+ (instancetype)modelWithContact:(CNContact *)contact;
- (NSString *)groupName;

@end

@interface HMContactModel : HMBaseModel <HMContactModel>
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) NSString *groupName;
@property(strong, nonatomic) NSString *firstName;
@property(strong, nonatomic) NSString *lastName;
@property(strong, nonatomic) NSData *imageData;
@property(getter=fullname, readonly) NSString *fullName;

@end
