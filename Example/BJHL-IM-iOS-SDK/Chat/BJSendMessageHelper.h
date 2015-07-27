//
//  BJSendMessageHelper.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Conversation.h>

#import <IMMessage.h>
#import <BJIMManager.h>

#import "BJChatInfo.h"
@interface BJSendMessageHelper : NSObject
+ (void)sendTextMessage:(NSString *)text chatInfo:(BJChatInfo *)chatInfo;
+ (void)sendAudioMessage:(NSString *)filePath duration:(NSInteger)duration chatInfo:(BJChatInfo *)chatInfo;
+ (void)sendImageMessage:(NSString *)filePath chatInfo:(BJChatInfo *)chatInfo;

+ (void)sendEmojiMessage:(NSString *)emoji chatInfo:(BJChatInfo *)chatInfo;
@end
