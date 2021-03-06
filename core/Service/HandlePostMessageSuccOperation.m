//
//  HandlePostMessageSuccOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/21.
//
//

#import "HandlePostMessageSuccOperation.h"
#import "BJIMService.h"
#import "IMMessage.h"
#import "SendMsgModel.h"
#import "Group.h"
#import "Conversation.h"

#import "IMCardMessageBody.h"
@implementation HandlePostMessageSuccOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    
    self.message.status = eMessageStatus_Send_Succ;
    if (self.message.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService.imStorage.groupDao load:self.message.receiver];
        group.lastMessageId = self.model.msgId;
        group.endMessageId = self.model.msgId;
        
        [self.imService.imStorage.groupDao insertOrUpdate:group];
    }
    
    self.message.msgId = self.model.msgId;
    IMMessage *__message = [self.imService.imStorage.messageDao loadWithMessageId:self.model.msgId];
    if (__message)
    {
        // 该消息 ID 已存在本地。 属于重复消息
        [__message deleteToDB];
        
    }
    self.message.createAt = self.model.createAt;
    if ([self.model.body length] > 0)
    {
        self.message.msg_t = eMessageType_CARD;
        NSDictionary *dictioanry = [NSJSONSerialization JSONObjectWithData:[self.model.body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        NSError *error;
        self.message.messageBody = [IMCardMessageBody modelWithDictionary:dictioanry error:&error];
    }
    
    [self.imService.imStorage.messageDao update:self.message];
    
    Conversation *conversation = [self.imService.imStorage.conversationDao loadWithOwnerId:self.message.sender
                                                                                 ownerRole:self.message.senderRole otherUserOrGroupId:self.message.receiver userRole:self.message.receiverRole chatType:self.message.chat_t];
    
    conversation.lastMessageId = self.message.msgId;
    [self.imService.imStorage.conversationDao update:conversation];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyDeliverMessage:self.message errorCode:RESULT_CODE_SUCC error:nil];
    [self.imService notifyConversationChanged];
}
@end
