//
//  BJTextChatCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJTextChatCell.h"
#import "BJChatCellFactory.h"
#import <BJIMConstants.h>
#import <PureLayout/PureLayout.h>

@implementation BJTextChatCell

+ (void)load
{
    [ChatCellFactoryInstance registerClass:[self class] forMessageType:eMessageType_TXT];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.bubbleContainerView.bounds;
    frame.size.width -= BUBBLE_ARROW_WIDTH;
    frame = CGRectInset(frame, BUBBLE_VIEW_PADDING, BUBBLE_VIEW_PADDING);
    if (self.message.isMySend) {
        frame.origin.x = BUBBLE_VIEW_PADDING;
    }else{
        frame.origin.x = BUBBLE_VIEW_PADDING + BUBBLE_ARROW_WIDTH;
    }
    
    frame.origin.y = BUBBLE_VIEW_PADDING;
    [self.contentLabel setFrame:frame];
    self.backImageView.frame = self.bubbleContainerView.bounds;
}

#pragma mark - Protocol
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    return [[BJTextChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([BJTextChatCell class])];
}

-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    [super setCellInfo:info indexPath:indexPath];
    
    NSString *imageName = !self.message.isMySend ? BUBBLE_LEFT_IMAGE_NAME : BUBBLE_RIGHT_IMAGE_NAME;
    NSInteger leftCapWidth = !self.message.isMySend?BUBBLE_LEFT_LEFT_CAP_WIDTH:BUBBLE_RIGHT_LEFT_CAP_WIDTH;
    NSInteger topCapHeight =  !self.message.isMySend?BUBBLE_LEFT_TOP_CAP_HEIGHT:BUBBLE_RIGHT_TOP_CAP_HEIGHT;
    self.backImageView.image = [[UIImage imageNamed:imageName] stretchableImageWithLeftCapWidth:leftCapWidth topCapHeight:topCapHeight];
    self.contentLabel.text = self.message.content;
    CGRect contentRect = self.contentLabel.frame;
    contentRect.size.width = TEXTLABEL_MAX_WIDTH;
    self.contentLabel.frame = contentRect;
    [self.contentLabel sizeToFit];
    contentRect = self.contentLabel.frame;
    contentRect.size.width = contentRect.size.width + BUBBLE_VIEW_PADDING*2;
    contentRect.size.height = contentRect.size.height + BUBBLE_VIEW_PADDING*2;
    self.bubbleContainerView.frame = contentRect;
}


#pragma mark - set get
- (UIImageView *)backImageView
{
    if (_backImageView == nil) {
        _backImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _backImageView.userInteractionEnabled = YES;
        _backImageView.multipleTouchEnabled = YES;
        [self.bubbleContainerView addSubview:_backImageView];
    }
    return _backImageView;
}

- (UILabel *)contentLabel
{
    if (_contentLabel == nil) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentLabel.numberOfLines = 0;
        _contentLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _contentLabel.font = [UIFont systemFontOfSize:NAME_LABEL_FONT_SIZE];
        _contentLabel.backgroundColor = [UIColor clearColor];
        _contentLabel.userInteractionEnabled = NO;
        _contentLabel.multipleTouchEnabled = NO;
        [self.bubbleContainerView addSubview:_contentLabel];
    }
    return _contentLabel;
}

@end
