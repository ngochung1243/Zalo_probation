//
//  ContactTableObject.m
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import "ContactTableObject.h"
#import "Constaint.h"
#import "UIImage+Utils.h"

@implementation ContactTableObject

#define Padding UIEdgeInsetsMake(5, 10, 5, 10)
#define NameFontSize 15

- (id)initWithBlock:(NICellDrawRectBlock)block object:(id)object {
    if ((self = [super initWithCellClass:[ContactTableCell class]])) {
        self.block = block;
        self.object = object;
    }
    return self;
}

+ (instancetype)objectWithContact:(ContactModel *)contact {
    return [ContactTableObject objectWithBlock:^CGFloat(CGRect rect, id object, UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        UIImage *avatar = contact.imageData ? contact.imageData : [UIImage defaultCircleImageWithSize:AvatarSize];
        [avatar drawAtPoint:CGPointMake(Padding.left, Padding.top)];
        NSString *fullName = contact.fullName;
        UIFont *nameFont = [UIFont systemFontOfSize:NameFontSize];
        [fullName drawAtPoint:CGPointMake(Padding.left + AvatarSize.width + Padding.left, CGRectGetMidY(rect) - nameFont.lineHeight/2) withAttributes:@{NSFontAttributeName: nameFont}];
        return 0;
    } object:contact];
}

@end

@implementation ContactTableCell

- (BOOL)shouldUpdateCellWithObject:(ContactTableObject *)object {
    return [super shouldUpdateCellWithObject:object];
}

@end
