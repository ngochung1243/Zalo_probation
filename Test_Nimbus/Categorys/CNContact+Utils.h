//
//  CNContact+Utils.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/23/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <Contacts/Contacts.h>

@interface CNContact (Utils)

@property(readonly, getter=fullName) NSString *fullName;
@property(readonly, getter=phoneNumberStrings) NSArray * phoneNumberStrings;
@end
