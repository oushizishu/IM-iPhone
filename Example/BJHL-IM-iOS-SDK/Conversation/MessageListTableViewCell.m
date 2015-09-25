//
//  MessageListTableViewCell.m
//  BJEducation_Institution
//
//  Created by Randy on 15/3/26.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "MessageListTableViewCell.h"
#import "JSBadgeView.h"
#import "UIView+Borders.h"
@interface MessageListTableViewCell ()
@property (strong, nonatomic)JSBadgeView *badgeView;
@property (strong, nonatomic)UIView *redView;
@end

@implementation MessageListTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.backgroundColor = [UIColor whiteColor];
    self.backgroundView = nil;
    self.contentView.backgroundColor = [UIColor whiteColor];
//    [self.contentView addBottomBorderWithHeight:0.5 andColor:APP_LINE_COLOR];
    self.photoImageView.layer.cornerRadius = 2;
    self.photoImageView.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleGray;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIView *)redView
{
    if (_redView == nil) {
        _redView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _redView.backgroundColor = [UIColor redColor];
        _redView.clipsToBounds = YES;
        _redView.layer.cornerRadius = 5;
    }
    return _redView;
}

- (void)setBadgeNumber:(NSString *)numStr
{
    [self.redView removeFromSuperview];
    if (numStr != nil){
        if(self.badgeView == nil){
            self.badgeView = [[JSBadgeView alloc] initWithParentView:self.badgeViewParent alignment:JSBadgeViewAlignmentTopRight];
            self.badgeView.badgePositionAdjustment = CGPointMake(-5, 5);
        }
        self.badgeView.badgeText = numStr;
        if (numStr.length<=0) {
            CGRect rect = self.redView.frame;
            rect.origin.x = self.badgeViewParent.frame.size.width - 8;
            rect.origin.y = -2;
            self.redView.frame = rect;
            [self.badgeViewParent addSubview:self.redView];
        }
    } else {
        [self.badgeView removeFromSuperview];
        self.badgeView = nil;
    }
}


@end
