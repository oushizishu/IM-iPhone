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

    //只要发消息，必须设置浅关注
    if ([self.imService.imStorage.socialContactsDao getTinyFoucsState:contact withOwner:owner] == eIMTinyFocus_None) {
        [self.imService.imStorage.socialContactsDao setContactTinyFoucs:eIMTinyFocus_Been contact:contact owner:owner];
    }
   
    
    IMBlackStatus blackStatus = [self.imService.imStorage.socialContactsDao getBlacklistState:contact witOwner:owner];
    
    self.remindMessageArray = [[NSMutableArray alloc] init];
    
    
    if (blackStatus == eIMBlackStatus_Active) {
        
        self.message.status = eMessageStatus_Send_Fail;
        [self.imService.imStorage.messageDao update:self.message];
        self.ifRefuse = YES;
        
        //黑名单提示消息
        IMNotificationMessageBody *messageBody = [[IMNotificationMessageBody alloc] init];
        messageBody.content = [NSString stringWithFormat:@"无法向对方发送消息，请先<a href='hermes:o.c?a=removeBlack&userNumber=%lld&userRole=%ld'>将对方移除黑名单</a>",contact.userId,contact.userRole];
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
        remindBlacklistMessage.msgId = [NSString stringWithFormat:@"%015.3lf", [[self.imService.imStorage.messageDao queryAllMessageMaxMsgId] doubleValue] + 0.001];
        remindBlacklistMessage.conversationId = conversation.rowid;
        remindBlacklistMessage.status = eMessageStatus_Send_Succ;
        [self.imService.imStorage.messageDao insert:remindBlacklistMessage];
        [self.remindMessageArray addObject:remindBlacklistMessage];
    }else{
        if(contact.userRole == eUserRole_Teacher || contact.userRole == eUserRole_Student || contact.userRole == eUserRole_Institution)
        {
            //未设置对方黑名单，再判断是否关注对方(浅关注也提示)，插入唯一性提示关注对方消息
            IMFocusType focusType = [self.imService.imStorage.socialContactsDao getAttentionState:contact withOwner:owner];
            if(focusType == eIMFocusType_None || focusType == eIMFocusType_Passive)
            {
                NSString *sign = @"HERMES_MESSAGE_NOFOCUS_SIGN";
                NSString *remindAttentionMsgId = [self.imService.imStorage.messageDao querySignMsgIdInConversation:conversation.rowid withSing:sign];
                
                if (remindAttentionMsgId == nil) {
                    IMNotificationMessageBody *messageBody = [[IMNotificationMessageBody alloc] init];
                    messageBody.content = [NSString stringWithFormat:@"<a href='hermes://o.c?a=addAttention@userNumber=%lld&userRole=%ld/'>点此关注对方，</a>可以在我的关注中找到对方哟",contact.userId,contact.userRole];
                    messageBody.type = eTxtMessageContentType_RICH_TXT;
                    IMMessage *remindAttentionMessage = [[IMMessage alloc] init];
                    remindAttentionMessage.messageBody = messageBody;
                    remindAttentionMessage.createAt = [NSDate date].timeIntervalSince1970;
                    remindAttentionMessage.chat_t = eChatType_Chat;
                    remindAttentionMessage.msg_t = eMessageType_NOTIFICATION;
                    remindAttentionMessage.receiver = owner.userId;
                    remindAttentionMessage.receiverRole = owner.userRole;
                    remindAttentionMessage.sender = contact.userId;
                    remindAttentionMessage.senderRole = contact.userRole;
                    remindAttentionMessage.msgId = [NSString stringWithFormat:@"%015.3lf", [[self.imService.imStorage.messageDao queryAllMessageMaxMsgId] doubleValue] + 0.001];
                    remindAttentionMessage.sign = sign;
                    remindAttentionMessage.conversationId = conversation.rowid;
                    remindAttentionMessage.status = eMessageStatus_Send_Succ;
                    [self.imService.imStorage.messageDao insert:remindAttentionMessage];
                    [self.remindMessageArray addObject:remindAttentionMessage];
                }
            }
        }
    }
    
}

- (void)doAfterOperationOnMain
{
    if (self.ifRefuse) {
        [self.imService notifyDeliverMessage:self.message errorCode:-1 error:nil];
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
    if (self.remindMessageArray != nil && [self.remindMessageArray count]>0) {
        [self.imService notifyReceiveNewMessages:self.remindMessageArray];
    }
}



@end
