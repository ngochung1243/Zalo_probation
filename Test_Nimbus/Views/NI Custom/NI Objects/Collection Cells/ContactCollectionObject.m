//
//  ContactCollectionObject.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ContactCollectionObject.h"
#import "UIImage+Utils.h"

@implementation ContactCollectionObject 

+ (instancetype)objectWithContact:(ContactModel *)contact {
    ContactCollectionObject *contactObject = [[ContactCollectionObject alloc] init];
    if (contactObject) {
        contactObject.contact = contact;
    }
    return contactObject;
}

#pragma mark - NICollectionViewCellObject

- (Class)collectionViewCellClass {
    return [ContactCollectionCell class];
}

@end

@implementation ContactCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _avatarImageView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:_avatarImageView];
    }
    
    return self;
}

- (BOOL)shouldUpdateCellWithObject:(ContactCollectionObject *)object {
    ContactModel *contact = object.contact;
    _avatarImageView.image = contact.imageData ? contact.imageData : [UIImage defaultCircleImageWithSize:AvatarSize];
    return YES;
}

@end
