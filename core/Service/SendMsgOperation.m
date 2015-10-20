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
                Conversation *stangerConversation = [self.imService getConversationUserOrGroupId:-1000100 userRole:-2 ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
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
    
    [self.imService.imStorage.conversationDao update:conversation];
    [self.imService.imStorage.messageDao update:self.message];
}

- (void)doAfterOperationOnMain
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

@end
