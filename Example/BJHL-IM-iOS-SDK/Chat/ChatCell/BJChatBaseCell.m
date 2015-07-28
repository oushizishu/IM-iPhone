//
//  BJChatBaseBubbleCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatBaseCell.h"
#import <UIImageView+Aliyun.h>

@implementation BJChatBaseCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupConfigure];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupConfigure];
    }
    return self;
}

- (void)setupConfigure
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bubbleViewPressed:)];
    [self addGestureRecognizer:tap];
    self.backgroundColor = [UIColor clearColor];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.headImageView.frame;
    frame.origin.x = self.message.isMySend ? (self.bounds.size.width - self.headImageView.frame.size.width - HEAD_PADDING) : HEAD_PADDING;
    self.headImageView.frame = frame;
    
//    self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.headImageView.frame)+5, CGRectGetMinY(self.headImageView.frame), (self.bounds.size.width - (CGRectGetMaxX(self.headImageView.frame)+5)*2), NAME_LABEL_HEIGHT);
    
    CGRect bubbleFrame = self.bubbleContainerView.frame;
    bubbleFrame.origin.y = CGRectGetMinY(self.headImageView.frame);
    
    if (self.message.isMySend) {
        // 菊花状态 （因不确定菊花具体位置，要在子类中实现位置的修改）
        switch (self.message.deliveryStatus) {
            case eMessageStatus_Sending:
            {
                [self.activityView setHidden:NO];
                [self.retryButton setHidden:YES];
                [self.activtiy setHidden:NO];
                [self.activtiy startAnimating];
            }
                break;
            case eMessageStatus_Send_Succ:
            {
                [self.activtiy stopAnimating];
                [self.activityView setHidden:YES];
                
            }
                break;
            case eMessageStatus_Send_Fail:
            {
                [self.activityView setHidden:NO];
                [self.activtiy stopAnimating];
                [self.activtiy setHidden:YES];
                [self.retryButton setHidden:NO];
            }
                break;
            default:
                break;
        }
        
        bubbleFrame.origin.x = self.headImageView.frame.origin.x - bubbleFrame.size.width - HEAD_PADDING;
        self.bubbleContainerView.frame = bubbleFrame;
        
        CGRect frame = self.activityView.frame;
        frame.origin.x = bubbleFrame.origin.x - frame.size.width - ACTIVTIYVIEW_BUBBLE_PADDING;
        frame.origin.y = self.bubbleContainerView.center.y - frame.size.height / 2;
        self.activityView.frame = frame;
    }
    else{
        bubbleFrame.origin.x = HEAD_PADDING * 2 + HEAD_SIZE;
        self.bubbleContainerView.frame = bubbleFrame;
    }
}

#pragma mark public
- (void)bubbleViewPressed:(id)sender
{
    [self routerEventWithName:kRouterEventChatCellBubbleTapEventName userInfo:@{kRouterEventUserInfoObject:self.message}];
}

- (UIImage *)bubbleImage
{
    NSString *imageName = !self.message.isMySend ? BUBBLE_LEFT_IMAGE_NAME : BUBBLE_RIGHT_IMAGE_NAME;
    NSInteger leftCapWidth = !self.message.isMySend?BUBBLE_LEFT_LEFT_CAP_WIDTH:BUBBLE_RIGHT_LEFT_CAP_WIDTH;
    NSInteger topCapHeight =  !self.message.isMySend?BUBBLE_LEFT_TOP_CAP_HEIGHT:BUBBLE_RIGHT_TOP_CAP_HEIGHT;
    return [[UIImage imageNamed:imageName] stretchableImageWithLeftCapWidth:leftCapWidth topCapHeight:topCapHeight];
}

#pragma mark - action
- (void)retryButtonPressed
{
    [super routerEventWithName:kResendButtonTapEventName userInfo:@{kRouterEventUserInfoObject:self.message}];
}

#pragma mark - Protocol
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    NSAssert(0, @"请子类实现此方法");
    return nil;
}
-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    self.message = info;
    self.indexPath = indexPath;
    UIImage *placeholderImage = [UIImage imageNamed:@"img_head_default"];
    [self.headImageView setAliyunImageWithURL:self.message.headImageURL placeholderImage:placeholderImage size:CGSizeMake(HEAD_SIZE, HEAD_SIZE)];
//    self.nameLabel.text = self.message.nickName;
}

+ (CGFloat)cellHeightWithInfo:(id)dic indexPath:(NSIndexPath *)indexPath;
{
    static BJChatBaseCell *cell = nil;
    if (cell == nil) {
        cell = [[self alloc] init];
    }
    
    [cell setCellInfo:dic indexPath:indexPath];
    CGFloat height = cell.bubbleContainerView.frame.size.height;
    if (height < cell.headImageView.frame.size.height) {
        height = cell.headImageView.frame.size.height;
    }
    return height + CELLPADDING*2;
}

#pragma mark - set get
- (UIImageView *)headImageView
{
    if (_headImageView == nil) {
        _headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(HEAD_PADDING, CELLPADDING, HEAD_SIZE, HEAD_SIZE)];
        _headImageView.userInteractionEnabled = YES;
        _headImageView.multipleTouchEnabled = YES;
        _headImageView.backgroundColor = [UIColor grayColor];
        _headImageView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_headImageView];
    }
    return _headImageView;
}

//- (UILabel *)nameLabel
//{
//    if (_nameLabel == nil) {
//        _nameLabel = [[UILabel alloc] init];
//        _nameLabel.backgroundColor = [UIColor clearColor];
//        _nameLabel.textColor = [UIColor grayColor];
//        _nameLabel.textAlignment = NSTextAlignmentLeft;
//        _nameLabel.font = [UIFont systemFontOfSize:12];
//        [self.contentView addSubview:_nameLabel];
//    }
//    return _nameLabel;
//}

- (UIView *)bubbleContainerView
{
    if (_bubbleContainerView == nil) {
        _bubbleContainerView = [[UIView alloc] init];
        [self.contentView addSubview:_bubbleContainerView];
    }
    return _bubbleContainerView;
}

- (UIActivityIndicatorView *)activtiy
{
    if (_activity == nil) {
        // 菊花
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activity.backgroundColor = [UIColor clearColor];
        [self.activityView addSubview:_activity];
    }
    return _activity;
}

- (UIView *)activityView
{
    if (_activityView == nil) {
        // 发送进度显示view
        _activityView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SEND_STATUS_SIZE, SEND_STATUS_SIZE)];
        [_activityView setHidden:YES];
        [self.contentView addSubview:_activityView];
    }
    return _activityView;
}

- (UIButton *)retryButton
{
    if (_retryButton == nil) {
        // 重发按钮
        _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _retryButton.frame = CGRectMake(0, 0, SEND_STATUS_SIZE, SEND_STATUS_SIZE);
        [_retryButton addTarget:self action:@selector(retryButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [_retryButton setImage:[UIImage imageNamed:@"ic_warn_nor"]  forState:UIControlStateNormal];
        [self.activityView addSubview:_retryButton];
    }
    return _retryButton;
}

@end
