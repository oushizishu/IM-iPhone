//
//  IMMessage+ViewModel.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "IMMessage.h"

@interface IMMessage (ViewModel)

- (BOOL)isMySend;    //是否是自己发送的
- (BOOL)isRead;      //是否已读

- (IMMessageStatus)deliveryStatus;

- (NSURL *)headImageURL;
- (NSString *)nickName;
- (NSAttributedString *)nickNameAttri;

//text
- (NSString *)content;

//image
- (CGSize)imageSize;
- (NSURL *)imageURL;

//EMOJI
- (NSURL *)emojiImageURL;
- (CGSize)emojiSize;

//audio
- (NSURL *)audioURL;
- (NSInteger)time;
- (BOOL)isPlayed;
- (BOOL)isPlaying;

//card
- (NSString *)cardTitle;
- (NSString *)cardContent;
- (NSString *)cardUrl;
- (NSString *)cardThumb;

//gossip 通知和cmd显示消息
- (NSString *)gossipText;

@end
