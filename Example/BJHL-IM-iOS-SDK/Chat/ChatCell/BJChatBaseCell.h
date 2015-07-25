//
//  BJChatBaseBubbleCell.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJChatViewCellProtocol.h"
#import <IMMessage.h>
#import "IMMessage+ViewModel.h"

#define HEAD_SIZE 40 // 头像大小
#define HEAD_PADDING 5 // 头像到cell的内间距和头像到bubble的间距
#define CELLPADDING 4 // Cell之间间距

#define NAME_LABEL_WIDTH 180 // nameLabel宽度
#define NAME_LABEL_HEIGHT 20 // nameLabel 高度
#define NAME_LABEL_PADDING 0 // nameLabel间距
#define NAME_LABEL_FONT_SIZE 14 // 字体

#define SEND_STATUS_SIZE 20 // 发送状态View的Size
#define ACTIVTIYVIEW_BUBBLE_PADDING 5 // 菊花和bubbleView之间的间距

@interface BJChatBaseCell : UITableViewCell<BJChatViewCellProtocol>
@property (strong, nonatomic)IMMessage *message;
@property (strong, nonatomic)NSIndexPath *indexPath;

@property (nonatomic, strong) UIImageView *headImageView;       //头像
//@property (nonatomic, strong) UILabel *nameLabel;               //姓名
@property (nonatomic, strong) UIView *bubbleContainerView;   //内容区域

//sender
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UIView *activityView;
@property (nonatomic, strong) UIButton *retryButton;

-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
@end