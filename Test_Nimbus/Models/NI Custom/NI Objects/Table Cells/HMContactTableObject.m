//
//  ContactTableObject.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "HMContactTableObject.h"
#import "Constaint.h"
#import "UIImage+Utils.h"
#import "Masonry.h"
#import "HMContactModel.h"
#import "HMImageMemoryCache.h"
#import "UIImageView+Utils.h"

@implementation HMContactTableObject

+ (instancetype)objectWithModel:(id)model {
    HMContactTableObject *cellObject = [[HMContactTableObject alloc] initWithCellClass:[HMContactTableCell class]];
    cellObject.model = model;
    return cellObject;
}

- (id)getModel {
    return _model;
}

- (NSComparisonResult)compare:(id)object {
    if ([object isKindOfClass:[HMContactTableObject class]]) {
        return [self.model compare:((HMContactTableObject *)object).model];
    }
    
    return NSOrderedSame;
}

@end

@implementation HMContactTableCell

#define DefaultCellColor           UIColor.whiteColor
#define Padding UIEdgeInsetsMake(5, 10, 5, 10)
#define NameFontSize 15

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = DefaultCellColor;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.selectedBackgroundView.hidden = YES;
        
        _avatarView = [[UIImageView alloc] init];
        _avatarView.alpha = 1;
        _avatarView.backgroundColor = DefaultCellColor;
        [self.contentView addSubview:_avatarView];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(Padding.left);
            make.size.mas_equalTo(AvatarSize);
        }];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:NameFontSize];
        [self.contentView addSubview:_nameLabel];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.left.equalTo(_avatarView.mas_right).offset(Padding.left);
        }];
    }
    
    return self;
}

- (BOOL)shouldUpdateCellWithObject:(id)object {
    if ([object conformsToProtocol:@protocol(HMCellObject)]) {
        id model = [(id<HMCellObject>)object getModel];
        if ([model isKindOfClass:[HMContactModel class]]) {
            HMContactModel *contactModel = model;
            id storeImage = [[HMImageMemoryCache shareInstance] objectWithName:contactModel.identifier];
            if (storeImage && [storeImage isKindOfClass:[UIImage class]]) {
                _avatarView.image = storeImage;
            } else {
                if (contactModel.imageData){
                    [_avatarView asyncLoadCircleImageWithData:contactModel.imageData completion:^(UIImage *image) {
                        [[HMImageMemoryCache shareInstance] storeObject:image withName:contactModel.identifier];
                    }];
                } else {
                    dispatch_async(globalDefaultQueue, ^{
                        UIImage *image = [UIImage letterImageWithString:contactModel.fullName textColor:UIColor.whiteColor andBackgroundColor:nil withSize:AvatarSize];
                        dispatch_async(mainQueue, ^{
                            _avatarView.image = image;
                            [[HMImageMemoryCache shareInstance] storeObject:image withName:contactModel.identifier];
                        });
                    });
                }
            }
            
            _nameLabel.text = contactModel.fullName;
        }
    }
    return YES;
}

@end
