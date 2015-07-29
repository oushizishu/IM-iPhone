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

+ (instancetype)sharedInstance
{
    static BJSendMessageHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

+ (void)sendMessage:(IMMessage *)message
{
    if ([[BJSendMessageHelper sharedInstance].deledate respondsToSelector:@selector(willSendMessage:)]) {
        [[BJSendMessageHelper sharedInstance].deledate willSendMessage:message];
    }
    [[BJIMManager shareInstance] sendMessage:message];
}

#pragma mark - 消息发送
+ (IMMessage *)sendTextMessage:(NSString *)text chatInfo:(BJChatInfo *)chatInfo;
{
    IMTxtMessageBody *messageBody = [[IMTxtMessageBody alloc] init];
    messageBody.content = text;
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.createAt = [NSDate date].timeIntervalSince1970;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_TXT;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [BJSendMessageHelper sendMessage:message];
    return message;
}

+ (IMMessage *)sendAudioMessage:(NSString *)filePath duration:(NSInteger)duration chatInfo:(BJChatInfo *)chatInfo;
{
    IMAudioMessageBody *messageBody = [[IMAudioMessageBody alloc] init];
    messageBody.file = filePath;
    messageBody.length = duration;
    
    IMMessage *message = [[IMMessage alloc] init];
    message.createAt = [NSDate date].timeIntervalSince1970;
    message.messageBody = messageBody;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_AUDIO;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [BJSendMessageHelper sendMessage:message];
    return message;
}

+ (IMMessage *)sendImageMessage:(NSString *)filePath imageSize:(CGSize)size chatInfo:(BJChatInfo *)chatInfo;
{
    IMImgMessageBody *messageBody = [[IMImgMessageBody alloc] init];
    messageBody.file = filePath;
    messageBody.width = size.width;
    messageBody.height = size.height;
    
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.createAt = [NSDate date].timeIntervalSince1970;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_IMG;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [BJSendMessageHelper sendMessage:message];
    return message;
}

+ (IMMessage *)sendEmojiMessage:(NSString *)emoji chatInfo:(BJChatInfo *)chatInfo;
{
    IMEmojiMessageBody *messageBody = [[IMEmojiMessageBody alloc] init];
    messageBody.name = emoji;
    messageBody.type = EmojiContent_GIF;
    
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.createAt = [NSDate date].timeIntervalSince1970;
    message.chat_t = chatInfo.chat_t;
    message.msg_t = eMessageType_EMOJI;
    message.receiver = chatInfo.getToId;
    message.receiverRole = chatInfo.getToRole;
    [BJSendMessageHelper sendMessage:message];
    return message;
}

@end
