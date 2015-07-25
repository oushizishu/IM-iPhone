//
//  BJTextChatCell.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatBaseCell.h"

#define BUBBLE_LEFT_IMAGE_NAME @"bg_speech_nor" // bubbleView 的背景图片
#define BUBBLE_RIGHT_IMAGE_NAME @"bg_speech_gre_nor"

#define BUBBLE_ARROW_WIDTH 5 // bubbleView中，箭头的宽度
#define BUBBLE_VIEW_PADDING 10 // bubbleView 与 在其中的控件内边距

#define BUBBLE_RIGHT_LEFT_CAP_WIDTH 5 // 文字在右侧时,bubble用于拉伸点的X坐标
#define BUBBLE_RIGHT_TOP_CAP_HEIGHT 35 // 文字在右侧时,bubble用于拉伸点的Y坐标

#define BUBBLE_LEFT_LEFT_CAP_WIDTH 35 // 文字在左侧时,bubble用于拉伸点的X坐标
#define BUBBLE_LEFT_TOP_CAP_HEIGHT 35 // 文字在左侧时,bubble用于拉伸点的Y坐标

#define BUBBLE_PROGRESSVIEW_HEIGHT 10 // progressView 高度


#define TEXTLABEL_MAX_WIDTH 200 // textLaebl 最大宽度

@interface BJTextChatCell : BJChatBaseCell
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) UILabel *contentLabel;
@end
