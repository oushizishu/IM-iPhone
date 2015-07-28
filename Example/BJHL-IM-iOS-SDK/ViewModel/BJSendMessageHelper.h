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

@protocol BJSendMessageProtocol <NSObject>

- (void)willSendMessage:(IMMessage *)message;

@end

@interface BJSendMessageHelper : NSObject
@property (weak, nonatomic) id<BJSendMessageProtocol>deledate;
+ (instancetype)sharedInstance;

/**
 *  发送消息业务层调用请都用这个方法，会有一些处理。
 *
 *  @param message 
 */
+ (void)sendMessage:(IMMessage *)message;

+ (IMMessage *)sendTextMessage:(NSString *)text chatInfo:(BJChatInfo *)chatInfo;
+ (IMMessage *)sendAudioMessage:(NSString *)filePath duration:(NSInteger)duration chatInfo:(BJChatInfo *)chatInfo;
+ (IMMessage *)sendImageMessage:(NSString *)filePath imageSize:(CGSize)size chatInfo:(BJChatInfo *)chatInfo;

+ (IMMessage *)sendEmojiMessage:(NSString *)emoji chatInfo:(BJChatInfo *)chatInfo;
@end
