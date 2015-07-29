//
//  BJCardChatCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJCardChatCell.h"
#import "BJChatCellFactory.h"
#import <BJIMConstants.h>
#import <PureLayout/PureLayout.h>
#import <UIImageView+Aliyun.h>

#define ImageWH 60
#define Interval 10
#define CardWidth 212
#define CardHeight 130
#define ContentWidth 130

@interface BJCardChatCell ()
@property (strong, nonatomic) UIImageView *cardImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *contentLabel;
@end

@implementation BJCardChatCell

+ (void)load
{
    [ChatCellFactoryInstance registerClass:[self class] forMessageType:eMessageType_CARD];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.titleLabel.frame;
    frame.size = [self.titleLabel sizeThatFits:CGSizeMake(CardWidth-Interval*2, 40)];
    frame.origin.y = 10;
    self.titleLabel.frame = frame;
    
    if (self.message.cardThumb.length<=0) {
        [self.cardImageView setHidden:YES];
        frame = self.contentLabel.frame;
        frame.origin.y = self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height+5;
        frame.size = [self.contentLabel sizeThatFits:CGSizeMake(CardWidth-Interval*2, CardHeight-35)];
        frame.origin.x = Interval;
        self.contentLabel.frame = frame;
    }else
    {
        [self.cardImageView setHidden:NO];
        frame = self.contentLabel.frame;
        frame.origin.y = self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height+5;
        frame.size = [self.contentLabel sizeThatFits:CGSizeMake(ContentWidth, CardHeight-35)];
        frame.origin.x = Interval+ImageWH+5;
        self.contentLabel.frame = frame;
    }
    
    if (!self.message.isMySend) {
        CGRect frame = self.cardImageView.frame;
        frame.origin.y = frame.origin.y = self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height+5;
        frame.origin.x = CardWidth-ImageWH;
        self.cardImageView.frame = frame;
        
        frame = self.titleLabel.frame;
        frame.origin.x = Interval+5;
        self.titleLabel.frame = frame;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        
        frame = self.contentLabel.frame;
        frame.origin.x = Interval+5;
        self.contentLabel.frame = frame;
    }
    else
    {
        CGRect frame = self.cardImageView.frame;
        frame.origin.x = Interval;
        frame.origin.y = self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height+5;
        self.cardImageView.frame = frame;
        
        frame = self.titleLabel.frame;
        frame.origin.x = Interval;
        self.titleLabel.frame = frame;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        
        frame = self.contentLabel.frame;
        frame.origin.x = Interval+ImageWH+5;
        self.contentLabel.frame = frame;
    }

}

#pragma mark - Protocol
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([BJCardChatCell class])];
    if (self) {
        CGRect rect = self.bubbleContainerView.frame;
        rect.size.width = CardWidth;
        rect.size.height = CardHeight;
        self.bubbleContainerView.frame = rect;
    }
    return self;
}

-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    [super setCellInfo:info indexPath:indexPath];
    self.titleLabel.text = self.message.cardTitle;
    self.contentLabel.text = self.message.cardContent;
    [self.imageView setAliyunImageWithURL:[NSURL URLWithString:self.message.cardThumb] placeholderImage:nil size:self.imageView.frame.size];
    
    self.backImageView.image = [self bubbleImage];
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(CardWidth-Interval*2, 40)];
    CGSize contentSize = [self.contentLabel sizeThatFits:CGSizeMake(ContentWidth, CardHeight-55)];
    [self.contentLabel sizeToFit];
    CGRect rect = self.bubbleContainerView.frame;
    rect.size.height = titleSize.height + contentSize.height + Interval*2;
    self.bubbleContainerView.frame = rect;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - set get

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(Interval, Interval, CardWidth-Interval*2, 40)];
        [_titleLabel setFont:[UIFont systemFontOfSize:16]];
        _titleLabel.numberOfLines = 2;
        [self.bubbleContainerView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(Interval+ImageWH+5, 55, ContentWidth, CardHeight-55)];
        [_contentLabel setFont:[UIFont systemFontOfSize:14]];
        _contentLabel.numberOfLines = 4;
        [_contentLabel setTextColor:[UIColor darkGrayColor]];
        [self.bubbleContainerView addSubview:_contentLabel];
    }
    return _contentLabel;
}

@end
