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
        
        if(self.message.chat_t == eChatType_Chat)
        {
            User *user = [self.imService getUser:self.message.receiver role:self.message.receiverRole];
            //判断会话对象是否为陌生人
            if ([self.imService getIsStanger:user]) {
                conversation.relation = 1;
                
                //获取陌生人会话
                Conversation *stangerConversation = [self.imService getConversationUserOrGroupId:-1000100 userRole:eUserRole_Stanger ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
                if (stangerConversation == nil) {
                    stangerConversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:-1000100 toRole:-2 lastMessageId:self.message.msgId chatType:eChatType_Chat];
                    [self.imService.imStorage.conversationDao insert:stangerConversation];
                }else
                {
                    stangerConversation.lastMessageId = self.message.msgId;
                    [self.imService.imStorage.conversationDao update:stangerConversation];
                }
            }
        }
        
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
    
    User *owner = [IMEnvironment shareInstance].owner;
    User *contact = [self.imService.imStorage.userDao loadUser:self.message.receiver role:self.message.receiverRole];
    
    IMBlackStatus blackStatus = [self.imService.imStorage.socialContactsDao getBlacklistState:contact witOwner:owner];
    
    //拉黑对方后，不能给对方发送消息
    if (blackStatus == eIMBlackStatus_Active) {
        
        self.message.status = eMessageStatus_Send_Fail;
        self.ifRefuse = YES;
        
        //插入无法发送消息提示消息
        IMTxtMessageBody *messageBody = [[IMTxtMessageBody alloc] init];
        messageBody.content = @"";
        IMMessage *message = [[IMMessage alloc] init];
        message.messageBody = messageBody;
        message.createAt = [NSDate date].timeIntervalSince1970;
        message.chat_t = eChatType_Chat;
        message.msg_t = eMessageType_TXT;
        message.receiver = owner.userId;
        message.receiverRole = owner.userRole;
        
    }else
    {
        //判断陌生人关系，如果是陌生人关系，判断是否是浅关系，不是浅关系，设置为浅关系
        BOOL isStanger = isStanger = [self.imService.imStorage.socialContactsDao isStanger:contact withOwner:owner];
        
        if (isStanger) {
            [self.imService.imStorage.socialContactsDao setContactTinyFoucs:eIMTinyFocus_Been contact:contact owner:owner];
            
            Conversation *conversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:contact.userId userRole:contact.userRole chatType:eChatType_Chat];
            if(conversation != nil)
            {
                if(conversation.relation == eConversation_Relation_Stranger)
                {
                    conversation.relation = eConverastion_Relation_Normal;
                    [self.imService.imStorage.conversationDao update:conversation];
                    
                    Conversation *stangerConversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:-1000100 userRole:eUserRole_Stanger chatType:eChatType_Chat];
                    if(stangerConversation != nil)
                    {
                        if(stangerConversation.lastMessageId == conversation.lastMessageId)
                        {
                            NSArray *conversationArray = [self.imService.imStorage.conversationDao loadAllStrangerWithOwnerId:owner.userId userRole:owner.userRole];
                            if(conversationArray!=nil && [conversationArray count]>0)
                            {
                                Conversation *lastConversation = [conversationArray firstObject];
                                stangerConversation.lastMessageId = lastConversation.lastMessageId;
                            }else
                            {
                                stangerConversation.lastMessageId = nil;
                            }
                            [self.imService.imStorage.conversationDao update:stangerConversation];
                        }
                    }
                }
            }
        }
    }
    
    
    [self.imService.imStorage.conversationDao update:conversation];
    [self.imService.imStorage.messageDao update:self.message];
}

- (void)doAfterOperationOnMain
{
    if (self.ifRefuse) {
        
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
