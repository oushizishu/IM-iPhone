//
//  BJEmojiChatCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJEmojiChatCell.h"
#import "BJChatCellFactory.h"
#import <BJIMConstants.h>
#import <PureLayout/PureLayout.h>

#import "YLGIFImage.h"
#import "YLImageView.h"

@interface BJEmojiChatCell ()
@property (strong, nonatomic) YLImageView *emojiImageView;
@end

@implementation BJEmojiChatCell

+ (void)load
{
    [ChatCellFactoryInstance registerClass:[self class] forMessageType:eMessageType_EMOJI];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.bubbleContainerView.bounds;
    [self.emojiImageView setFrame:frame];
}

#pragma mark - 内部方法
- (CGSize)calculateCellHeight
{
    CGSize retSize = self.message.emojiSize;
    if (retSize.width == 0 || retSize.height == 0) {
        retSize.width = EMOJI_MAX_SIZE;
        retSize.height = EMOJI_MAX_SIZE;
    }else if (retSize.width > retSize.height) {
        CGFloat height =  EMOJI_MAX_SIZE / retSize.width  *  retSize.height;
        retSize.height = height;
        retSize.width = EMOJI_MAX_SIZE;
    }else {
        CGFloat width = EMOJI_MAX_SIZE / retSize.height * retSize.width;
        retSize.width = width;
        retSize.height = EMOJI_MAX_SIZE;
    }
    return retSize;
}

#pragma mark - Protocol
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([BJEmojiChatCell class])];
    if (self) {
        
    }
    return self;
}

-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    [super setCellInfo:info indexPath:indexPath];
    CGSize size = [self calculateCellHeight];
    self.emojiImageView.image = [YLGIFImage imageWithContentsOfFile:[self.message.emojiImageURL relativePath]];
    CGRect rect = self.emojiImageView.frame;
    rect.size = size;
    self.emojiImageView.frame = rect;
    
    rect = self.bubbleContainerView.frame;
    rect.size = size;
    self.bubbleContainerView.frame = rect;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - set get
- (YLImageView *)emojiImageView
{
    if (_emojiImageView == nil) {
        _emojiImageView = [[YLImageView alloc] initWithFrame:CGRectMake(0, 0, EMOJI_MAX_SIZE, EMOJI_MAX_SIZE)];
        [self.bubbleContainerView addSubview:_emojiImageView];

    }
    return _emojiImageView;
}

@end
