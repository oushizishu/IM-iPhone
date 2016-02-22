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
    
    Conversation *conversation = [self.imService getConversationUserOrGroupId:self.message.receiver userRole:self.message.receiverRole ownerId:self.message.sender ownerRole:self.message.senderRole chat_t:self.message.chat_t];
    
    User *owner = [IMEnvironment shareInstance].owner;
    if (conversation == nil)
    {
        conversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:self.message.receiver toRole:self.message.receiverRole lastMessageId:@"" chatType:self.message.chat_t];
        
        [self.imService insertConversation:conversation];
    }
    
    conversation.status = 0; //会话状态回归正常
    
    self.message.conversationId = conversation.rowid;
    
    self.message.msgId = [self.imService.imStorage nextFakeMessageId];
    
    conversation.lastMessageId = self.message.msgId;
    
    User *contact = [self.imService getUser:self.message.receiver role:self.message.receiverRole];
    
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
    }
    
    [self.imService.imStorage.conversationDao update:conversation];
    
    [self.imService.imStorage.messageDao insert:self.message];
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
