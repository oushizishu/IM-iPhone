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

@implementation SendMsgOperation

- (void)doOperationOnBackground
{
    self.message.read = 1;
    self.message.played = 1;
    
    
    [self.imService.imStorage insertMessage:self.message];
    
    Conversation *conversation = [self.imService.imStorage queryConversation:self.message.conversationId];
    
    if (conversation == nil)
    {
        //query conversation
        conversation = [self.imService.imStorage queryConversation:self.message.sender userRole:self.message.senderRole otherUserOrGroupId:self.message.receiver userRole:self.message.receiverRole chatType:self.message.chat_t];
    }
    
    if (conversation == nil)
    {
        conversation = [[Conversation alloc] init];
        conversation.ownerId = [IMEnvironment shareInstance].owner.userId;
        conversation.ownerRole = [IMEnvironment shareInstance].owner.userRole;
        conversation.toId = self.message.receiver;
        conversation.toRole = self.message.receiverRole;
        conversation.chat_t = self.message.chat_t;
    }
    
    conversation.lastMsgRowId = self.message.rowid;
    self.message.conversationId = conversation.rowid;
    
    self.message.msgId = MAX([self.imService.imStorage getConversationMaxMsgId:conversation.rowid], 0) + 0.001;
    
    if (self.message.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService.imStorage queryGroupWithGroupId:self.message.receiver];
        group.lastMessageId = self.message.msgId;
        group.endMessageId = self.message.msgId;
        [self.imService.imStorage updateGroup:group];
    }
    
    [self.imService.imStorage updateMessage:self.message];
}

- (void)doAfterOperationOnMain
{
    [self.imService.imEngine postMessage:self.message];
}

@end
