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
    
    Conversation *conversation = [self.imService getConversationUserOrGroupId:self.message.receiver userRole:self.message.receiverRole ownerId:self.message.sender ownerRole:self.message.senderRole chat_t:self.message.chat_t];
    
    if (conversation == nil)
    {
        User *owner = [IMEnvironment shareInstance].owner;
        conversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:self.message.receiver toRole:self.message.receiverRole lastMessageId:@"" chatType:self.message.chat_t];
        
        [self.imService insertConversation:conversation];
    }
    
    conversation.status = 0; //会话状态回归正常
    
    self.message.conversationId = conversation.rowid;
    
    self.message.msgId = [self.imService.imStorage nextFakeMessageId];
    
    conversation.lastMessageId = self.message.msgId;
    
    User *owner = [IMEnvironment shareInstance].owner;
    User *contact = [self.imService.imStorage.userDao loadUser:self.message.receiver role:self.message.receiverRole];
    
    if (self.message.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService.imStorage.groupDao load:self.message.receiver];
        group.lastMessageId = self.message.msgId;
        group.endMessageId = self.message.msgId;
        [self.imService.imStorage.groupDao insertOrUpdate:group];
        
        
        //TODO 检查群免打扰设置
    }
    else
    {
        //只要发消息，必须设置浅关注
        if ([self.imService.imStorage.socialContactsDao getTinyFoucsState:contact withOwner:owner] == eIMTinyFocus_None) {
            [self.imService.imStorage.socialContactsDao setContactTinyFoucs:eIMTinyFocus_Been contact:contact owner:owner];
            
            conversation.relation = [self.imService getIsStanger:owner withUser:contact]?eConversation_Relation_Stranger:eConverastion_Relation_Normal;
        }
    }
    
    [self.imService.imStorage.conversationDao update:conversation];
    
    IMBlackStatus blackStatus = [self.imService.imStorage.socialContactsDao getBlacklistState:contact witOwner:owner];
    if (blackStatus == eIMBlackStatus_Active)
    {
        self.remindMessageArray = [[NSMutableArray alloc] init];
        
        self.message.status = eMessageStatus_Send_Fail;
        self.ifRefuse = YES;
        
        //黑名单提示消息
        IMNotificationMessageBody *messageBody = [[IMNotificationMessageBody alloc] init];
        messageBody.content = [NSString stringWithFormat:@"<p>无法向对方发送消息，请先<a href=\"hermes://o.c?a=removeBlack&amp;userNumber=%lld&amp;userRole=%ld\">将对方移除黑名单</a></p>",contact.userId,contact.userRole];
        messageBody.type = eTxtMessageContentType_RICH_TXT;
        IMMessage *remindBlacklistMessage = [[IMMessage alloc] init];
        remindBlacklistMessage.messageBody = messageBody;
        remindBlacklistMessage.createAt = [NSDate date].timeIntervalSince1970;
        remindBlacklistMessage.chat_t = eChatType_Chat;
        remindBlacklistMessage.msg_t = eMessageType_NOTIFICATION;
        remindBlacklistMessage.receiver = owner.userId;
        remindBlacklistMessage.receiverRole = owner.userRole;
        remindBlacklistMessage.sender = contact.userId;
        remindBlacklistMessage.senderRole = contact.userRole;
        remindBlacklistMessage.msgId = [self.imService.imStorage nextFakeMessageId];
        remindBlacklistMessage.conversationId = conversation.rowid;
        remindBlacklistMessage.status = eMessageStatus_Send_Succ;
        
        [self.imService.imStorage.messageDao insert:remindBlacklistMessage];
        [self.remindMessageArray addObject:remindBlacklistMessage];
    }
    [self.imService.imStorage.messageDao insert:self.message];
}

- (void)doAfterOperationOnMain
{
    if (self.ifRefuse)
    {
        [self.imService notifyDeliverMessage:self.message errorCode:-1 error:nil];
        [self.imService notifyConversationChanged];
        
    }
    else
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
    
    // 提示消息
    if ([self.remindMessageArray count] > 0) {
        [self.imService notifyReceiveNewMessages:self.remindMessageArray];
    }
}

@end
