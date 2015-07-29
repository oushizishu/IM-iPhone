//
//  BJTipTextTableViewCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/29.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJGossipTableViewCell.h"
#import "BJChatCellFactory.h"
#import "BJChatBaseCell.h"

#define Gossip_Content_Label_Max_Width 200
#define Gossip_Content_Label_Height 18

@interface BJGossipTableViewCell ()
@property (strong, nonatomic) UILabel *contentLabel;
@end

@implementation BJGossipTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (void)load
{
    [[BJChatCellFactory sharedInstance] registerClass:[self class] forMessageType:eMessageType_CMD];
    [[BJChatCellFactory sharedInstance] registerClass:[self class] forMessageType:eMessageType_NOTIFICATION];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect rect = self.contentLabel.frame;
    rect.origin.x = self.frame.size.width - rect.size.width - CELLPADDING;
    self.contentLabel.frame = rect;
}

#pragma mark - Protocol
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([BJGossipTableViewCell class])];
    if (self) {
        
    }
    return self;
}
-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    self.message = info;
    self.indexPath = indexPath;
    self.contentLabel.text = self.message.gossipText;
    CGSize size = [self.contentLabel sizeThatFits:CGSizeMake(Gossip_Content_Label_Max_Width-14, Gossip_Content_Label_Height)];
    size.width+=14;
    size.height = Gossip_Content_Label_Height;
    CGRect rect = self.contentLabel.frame;
    rect.size = size;
    self.contentLabel.frame = rect;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

+ (CGFloat)cellHeightWithInfo:(id)dic indexPath:(NSIndexPath *)indexPath;
{
    return Gossip_Content_Label_Height+CELLPADDING*2;
}

#pragma mark - set get
- (UILabel *)contentLabel
{
    if (_contentLabel == nil) {
        _contentLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CELLPADDING, Gossip_Content_Label_Max_Width, Gossip_Content_Label_Height)];
            label.font = [UIFont systemFontOfSize:10];
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor = [UIColor grayColor];
            label.textColor = [UIColor whiteColor];
            label.layer.cornerRadius = Gossip_Content_Label_Height / 2;
            label.clipsToBounds = YES;
            label;
        });
        [self.contentView addSubview:self.contentLabel];
    }
    return _contentLabel;
}

@end
