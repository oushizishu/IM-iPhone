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
@implementation BJSendMessageHelper
#pragma mark - 消息发送
+ (void)sendTextMessage:(NSString *)text conversation:(Conversation *)conversation;
{
    IMTxtMessageBody *messageBody = [[IMTxtMessageBody alloc] init];
    messageBody.content = text;
    
    IMMessage *message = [[IMMessage alloc] init];
    message.messageBody = messageBody;
    message.chat_t = conversation.chat_t;
    message.msg_t = eMessageType_TXT;
    message.receiver = conversation.toId;
    message.receiverRole = conversation.toRole;
    message.sender = conversation.ownerId;
    message.senderRole = conversation.ownerRole;
    [[BJIMManager shareInstance] sendMessage:message];
}
@end
