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
    
    
    [self.imService.imStorage insertMessage:self.message];
    
    Conversation *conversation = [self.imService.imStorage queryConversation:self.message.sender ownerRole:self.message.senderRole otherUserOrGroupId:self.message.receiver userRole:self.message.receiverRole chatType:self.message.chat_t];
    
    if (conversation == nil)
    {
        //query conversation
        conversation = [self.imService.imStorage queryConversation:self.message.sender ownerRole:self.message.senderRole otherUserOrGroupId:self.message.receiver userRole:self.message.receiverRole chatType:self.message.chat_t];
    }
    
    if (conversation == nil)
    {
        User *owner = [IMEnvironment shareInstance].owner;
        conversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:self.message.receiver toRole:self.message.receiverRole lastMessageId:@"" chatType:self.message.chat_t];
        
        [self.imService.imStorage insertConversation:conversation];
    }
    conversation.status = 0; //会话状态回归正常
    
    self.message.conversationId = conversation.rowid;
    
    self.message.msgId = [NSString stringWithFormat:@"%.3lf", [[self.imService.imStorage queryAllMessageMaxMsgId] doubleValue] + 0.001];
    
    conversation.lastMessageId = self.message.msgId;
    
    if (self.message.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService getGroup:self.message.receiver];
        group.lastMessageId = self.message.msgId;
        group.endMessageId = self.message.msgId;
    }
    
    [self.imService.imStorage updateConversation:conversation];
    [self.imService.imStorage updateMessage:self.message];
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
