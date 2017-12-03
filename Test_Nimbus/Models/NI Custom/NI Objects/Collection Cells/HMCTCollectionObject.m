//
//  ContactCollectionObject.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMCTCollectionObject.h"
#import "UIImage+Utils.h"
#import "HMImageMemoryCache.h"
#import "UIImageView+Utils.h"

@implementation HMCTCollectionObject

+ (instancetype)objectWithModel:(id)model {
    HMCTCollectionObject *contactObject = [[HMCTCollectionObject alloc] init];
    if (contactObject) {
        contactObject.model = model;
    }
    return contactObject;
}

- (id)getModel {
    return _model;
}

- (NSComparisonResult)compare:(id)object {
    if ([object isKindOfClass:[HMCTCollectionObject class]]) {
        return [self.model compare:((HMCTCollectionObject *)object).model];
    }
    
    return NSOrderedSame;
}

#pragma mark - NICollectionViewCellObject

- (Class)collectionViewCellClass {
    return [HMCTCollectionCell class];
}

@end

@implementation HMCTCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _avatarImageView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:_avatarImageView];
    }
    
    return self;
}

- (BOOL)shouldUpdateCellWithObject:(HMCTCollectionObject *)object {
    HMContactModel *contact = object.model;
    id storeImage = [[HMImageMemoryCache shareInstance] objectWithName:contact.identifier];
    if (storeImage && [storeImage isKindOfClass:[UIImage class]]) {
        _avatarImageView.image = storeImage;
    } else {
        if (contact.imageData){
            [_avatarImageView asyncLoadCircleImageWithData:contact.imageData completion:^(UIImage *image) {
                [[HMImageMemoryCache shareInstance] storeObject:image withName:contact.identifier];
            }];
        } else {
            dispatch_async(globalDefaultQueue, ^{
                UIImage *image = [UIImage letterImageWithString:contact.fullName textColor:UIColor.whiteColor andBackgroundColor:nil withSize:AvatarSize];
                dispatch_async(mainQueue, ^{
                    _avatarImageView.image = image;
                    [[HMImageMemoryCache shareInstance] storeObject:image withName:contact.identifier];
                });
            });
        }
    }
    
    return YES;
}

@end
