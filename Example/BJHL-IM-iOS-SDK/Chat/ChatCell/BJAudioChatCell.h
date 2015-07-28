//
//  BJAudioChatCell.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatBaseCell.h"
#define ANIMATION_IMAGEVIEW_HEIGHT 17.5 // 小喇叭图片尺寸
#define ANIMATION_IMAGEVIEW_WIDTH 11
#define ANIMATION_IMAGEVIEW_SPEED 1 // 小喇叭动画播放速度


#define ANIMATION_TIME_IMAGEVIEW_PADDING 5 // 时间与动画间距


#define ANIMATION_TIME_LABEL_WIDHT 40 // 时间宽度
#define ANIMATION_TIME_LABEL_HEIGHT 15 // 时间高度
#define ANIMATION_TIME_LABEL_FONT_SIZE 14 // 时间字体

// 发送
#define SENDER_ANIMATION_IMAGEVIEW_IMAGE_DEFAULT @"ic_volume_li_gary3" // 小喇叭默认图片
#define SENDER_ANIMATION_IMAGEVIEW_IMAGE_01 @"ic_volume_li_gary1" // 小喇叭动画第一帧
#define SENDER_ANIMATION_IMAGEVIEW_IMAGE_02 @"ic_volume_li_gary2" // 小喇叭动画第二帧
#define SENDER_ANIMATION_IMAGEVIEW_IMAGE_03 @"ic_volume_li_gary3" // 小喇叭动画第三帧
#define SENDER_ANIMATION_IMAGEVIEW_IMAGE_04 @"ic_volume_li_gary3" // 小喇叭动画第四帧


// 接收
#define RECEIVER_ANIMATION_IMAGEVIEW_IMAGE_DEFAULT @"ic_volume_ri_gre3" // 小喇叭默认图片
#define RECEIVER_ANIMATION_IMAGEVIEW_IMAGE_01 @"ic_volume_ri_gre1" // 小喇叭动画第一帧
#define RECEIVER_ANIMATION_IMAGEVIEW_IMAGE_02 @"ic_volume_ri_gre2" // 小喇叭动画第二帧
#define RECEIVER_ANIMATION_IMAGEVIEW_IMAGE_03 @"ic_volume_ri_gre3" // 小喇叭动画第三帧
#define RECEIVER_ANIMATION_IMAGEVIEW_IMAGE_04 @"ic_volume_ri_gre3" // 小喇叭动画第四帧


@interface BJAudioChatCell : BJChatBaseCell
-(void)startAudioAnimation;
-(void)stopAudioAnimation;
@end
