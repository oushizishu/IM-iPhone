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
#import "IMEnvironment.h"

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
    
    User *owner = [IMEnvironment shareInstance].owner;
    User *contact = [self.imService.imStorage.userDao loadUser:self.message.receiver role:self.message.receiverRole];
    
    CONVERSATION_RELATION relation = conversation.relation;
    
    if (conversation.chat_t == eChatType_Chat) {
        if([self.imService getIsStanger:contact withUser:owner])
        {
            self.remindMessageArray = [[NSMutableArray alloc] init];
            NSString *sign = @"HERMES_MESSAGE_NOPASSIVE_SIGN";
            NSString *remindAttentionMsgId = [self.imService.imStorage.messageDao querySignMsgIdInConversation:conversation.rowid withSing:sign];
            
            if (remindAttentionMsgId == nil) {
                IMNotificationMessageBody *messageBody = [[IMNotificationMessageBody alloc] init];
                messageBody.content = @"<p>对方还没有关注你，消息将以陌生人身份发给对方</p>";
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
                remindAttentionMessage.msgId = [self.imService.imStorage nextFakeMessageId];
                remindAttentionMessage.sign = sign;
                remindAttentionMessage.conversationId = conversation.rowid;
                remindAttentionMessage.status = eMessageStatus_Send_Succ;
                [self.imService.imStorage.messageDao insert:remindAttentionMessage];
                [self.remindMessageArray addObject:remindAttentionMessage];
            }
        }
        
        conversation.relation = [self.imService getIsStanger:owner withUser:contact]?eConversation_Relation_Stranger:eConverastion_Relation_Normal;
        
        
        if (relation != conversation.relation) {
            Conversation *strangerConversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:USER_STRANGER userRole:eUserRole_Stanger chatType:eChatType_Chat];
            if (strangerConversation == nil) {
                strangerConversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:USER_STRANGER toRole:eUserRole_Stanger lastMessageId:nil chatType:eChatType_Chat];
                [self.imService.imStorage.conversationDao insert:strangerConversation];
            }
            
            strangerConversation.lastMessageId = [self.imService.imStorage.conversationDao queryStrangerConversationsMaxMsgId:owner.userId ownerRole:owner.userRole];
            NSInteger count =[self.imService.imStorage.conversationDao countOfStrangerCovnersationAndUnreadNumNotZero:owner.userId userRole:owner.userRole];
            if (count != strangerConversation.unReadNum) {
                strangerConversation.status = 0;
            }
            strangerConversation.unReadNum = count;
            
            [self.imService.imStorage.conversationDao update:strangerConversation];
        }
    }
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyDeliverMessage:self.message errorCode:RESULT_CODE_SUCC error:nil];
    [self.imService notifyConversationChanged];
    if (self.remindMessageArray != nil && [self.remindMessageArray count]>0) {
        [self.imService notifyReceiveNewMessages:self.remindMessageArray];
    }
}
@end
