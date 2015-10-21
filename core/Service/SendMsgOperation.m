//
//  SendMsgOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "SendMsgOperation.h"
#import "Conversation.h"
#import "IMEnvironment.h"
#import "BJIMService.h"
#import "IMMessage.h"
@implementation SendMsgOperation

- (void)doOperationOnBackground
{
    self.message.read = 1;
    self.message.played = 1;
    self.ifRefuse = NO;
    
    
    [self.imService.imStorage.messageDao insert:self.message];
   
    Conversation *conversation = [self.imService getConversationUserOrGroupId:self.message.receiver userRole:self.message.receiverRole ownerId:self.message.sender ownerRole:self.message.senderRole chat_t:self.message.chat_t];
    
    if (conversation == nil)
    {
        User *owner = [IMEnvironment shareInstance].owner;
        conversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:self.message.receiver toRole:self.message.receiverRole lastMessageId:@"" chatType:self.message.chat_t];
        
        [self.imService insertConversation:conversation];
    }
    
    conversation.status = 0; //会话状态回归正常
    
    self.message.conversationId = conversation.rowid;
    
    self.message.msgId = [NSString stringWithFormat:@"%015.3lf", [[self.imService.imStorage.messageDao queryAllMessageMaxMsgId] doubleValue] + 0.001];
    
    conversation.lastMessageId = self.message.msgId;
    
    if (self.message.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService.imStorage.groupDao load:self.message.receiver];
        group.lastMessageId = self.message.msgId;
        group.endMessageId = self.message.msgId;
        [self.imService.imStorage.groupDao insertOrUpdate:group];
    }
    
    [self.imService.imStorage.conversationDao update:conversation];
    [self.imService.imStorage.messageDao update:self.message];
    
    
    User *owner = [IMEnvironment shareInstance].owner;
    User *contact = [self.imService.imStorage.userDao loadUser:self.message.receiver role:self.message.receiverRole];
    
    if ([self.imService.imStorage.socialContactsDao getTinyFoucsState:contact withOwner:owner] == eIMTinyFocus_None) {
        [self.imService.imStorage.socialContactsDao setContactTinyFoucs:eIMTinyFocus_Been contact:contact owner:owner];
    }
    
    IMBlackStatus blackStatus = [self.imService.imStorage.socialContactsDao getBlacklistState:contact witOwner:owner];
    
    if (blackStatus == eIMBlackStatus_Active) {
        
        self.message.status = eMessageStatus_Send_Fail;
        [self.imService.imStorage.messageDao update:self.message];
        self.ifRefuse = YES;
        
        //插入无法发送消息提示消息
        IMTxtMessageBody *messageBody = [[IMTxtMessageBody alloc] init];
        messageBody.content = @"您已拉黑对方，请先取消黑名单。";
        self.remindMessage = [[IMMessage alloc] init];
        self.remindMessage.messageBody = messageBody;
        self.remindMessage.createAt = [NSDate date].timeIntervalSince1970;
        self.remindMessage.chat_t = eChatType_Chat;
        self.remindMessage.msg_t = eMessageType_NOTIFICATION;
        self.remindMessage.receiver = owner.userId;
        self.remindMessage.receiverRole = owner.userRole;
        self.remindMessage.sender = USER_SYSTEM_SECRETARY;
        self.remindMessage.senderRole = eUserRole_System;
        self.remindMessage.msgId = [NSString stringWithFormat:@"%015.3lf", [[self.imService.imStorage.messageDao queryAllMessageMaxMsgId] doubleValue] + 0.001];
        
        [self.imService.imStorage.messageDao insert:self.remindMessage];
    }
    
}

- (void)doAfterOperationOnMain
{
    if (self.ifRefuse) {
        [self.imService notifyDeliverMessage:self.message errorCode:-1 error:nil];
        [self.imService notifyReceiveNewMessages:[NSArray arrayWithObjects:self.remindMessage, nil]];
        [self.imService notifyConversationChanged];
        
    }else
    {
        [self.imService notifyConversationChanged];
        if (self.message.msg_t == eMessageType_IMG || self.message.msg_t == eMessageType_AUDIO)
        {
            [self.imService.imEngine postMessageAchive:self.message];
        }
        else
        {
            [self.imService.imEngine postMessage:self.message];
        }
    }
}



@end
