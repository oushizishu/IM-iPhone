//
//  BJImageChatCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJImageChatCell.h"
#import "BJChatCellFactory.h"
#import <BJIMConstants.h>
#import <PureLayout/PureLayout.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <UIImageView+Aliyun.h>

@interface BJImageChatCell ()
@property (strong, nonatomic) UIImageView *chatImageView;
@end

@implementation BJImageChatCell

+ (void)load
{
    [ChatCellFactoryInstance registerClass:[self class] forMessageType:eMessageType_IMG];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.bubbleContainerView.bounds;
    [self.chatImageView setFrame:frame];
}

#pragma mark - 内部方法
- (CGSize)calculateCellHeight
{
    CGSize retSize = self.message.imageSize;
    NSLog(@"calculateCellHeight,%@",NSStringFromCGSize(retSize));
    if (retSize.width == 0 || retSize.height == 0) {
        retSize.width = MAX_SIZE;
        retSize.height = MAX_SIZE;
    }else if (retSize.width > retSize.height) {
        CGFloat height =  MAX_SIZE / retSize.width  *  retSize.height;
        retSize.height = height;
        retSize.width = MAX_SIZE;
    }else {
        CGFloat width = MAX_SIZE / retSize.height * retSize.width;
        retSize.width = width;
        retSize.height = MAX_SIZE;
    }
    return retSize;
}

- (void)bubbleViewPressed:(id)sender
{
    [super routerEventWithName:kRouterEventImageBubbleTapEventName userInfo:@{kRouterEventUserInfoObject:self.message}];
}

#pragma mark - Protocol
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([BJImageChatCell class])];
    if (self) {
        
    }
    return self;
}

-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    [super setCellInfo:info indexPath:indexPath];
    CGSize size = [self calculateCellHeight];
    @TODO("设置默认图片");
    [self.chatImageView setAliyunImageWithURL:self.message.imageURL placeholderImage:nil size:size];
    CGRect rect = self.chatImageView.frame;
    rect.size = size;
    self.chatImageView.frame = rect;
    UIImage *image = [self bubbleImage];
    UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
    imageViewMask.frame = CGRectInset(self.chatImageView.frame, 2.0f, 2.0f);
    self.chatImageView.layer.mask = imageViewMask.layer;
    
    rect = self.bubbleContainerView.frame;
    rect.size = size;
    self.bubbleContainerView.frame = rect;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - set get
- (UIImageView *)chatImageView
{
    if (_chatImageView == nil) {
        _chatImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _chatImageView.userInteractionEnabled = YES;
        _chatImageView.multipleTouchEnabled = YES;
        [self.bubbleContainerView addSubview:_chatImageView];
    }
    return _chatImageView;
}

@end
