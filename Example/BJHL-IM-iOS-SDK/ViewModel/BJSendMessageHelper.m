//
//  BJSendMessageHelper.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJSendMessageHelper.h"
#import <IMTxtMessageBody.h>
#import <IMAudioMessageBody.h>
#import <IMImgMessageBody.h>
#import <IMEmojiMessageBody.h>
#import "BJChatInfo.h"
@implementation BJSendMessageHelper
#pragma mark - 消息发送
+ (void)sendTextMessage:(NSString *)text chatInfo:(BJChatInfo *)chatInfo;
{
    IMTxtMessageBody *messageBody = [[IMTxtMessageBody alloc] init];
    messageBody.content = text;
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_TXT;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [[BJIMManager shareInstance] sendMessage:message];
}

+ (void)sendAudioMessage:(NSString *)filePath duration:(NSInteger)duration chatInfo:(BJChatInfo *)chatInfo;
{
    IMAudioMessageBody *messageBody = [[IMAudioMessageBody alloc] init];
    
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_AUDIO;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [[BJIMManager shareInstance] sendMessage:message];
    
}

+ (void)sendImageMessage:(NSString *)filePath chatInfo:(BJChatInfo *)chatInfo;
{
    IMImgMessageBody *messageBody = [[IMImgMessageBody alloc] init];
    
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_IMG;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [[BJIMManager shareInstance] sendMessage:message];
}

+ (void)sendEmojiMessage:(NSString *)emoji chatInfo:(BJChatInfo *)chatInfo;
{
    IMEmojiMessageBody *messageBody = [[IMEmojiMessageBody alloc] init];
    
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_EMOJI;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [[BJIMManager shareInstance] sendMessage:message];
}

@end
