//
//  PassiveBlacklistOperation.m
//  Pods
//
//  Created by bjhl on 15/10/22.
//
//

#import "PassiveBlacklistOperation.h"
#import "IMEnvironment.h"

@implementation PassiveBlacklistOperation

- (void)doOperationOnBackground
{
    
    Conversation *conversation = [self.imService getConversationUserOrGroupId:self.message.receiver userRole:self.message.receiverRole ownerId:self.message.sender ownerRole:self.message.senderRole chat_t:self.message.chat_t];
    
    if(conversation != nil)
    {
        User *owner = [IMEnvironment shareInstance].owner;
        User *contact = [self.imService.imStorage.userDao loadUser:self.message.receiver role:self.message.receiverRole];
        
        //我被对方拉黑，要插入提醒信息
        IMNotificationMessageBody *messageBody = [[IMNotificationMessageBody alloc] init];
        messageBody.content = @"对方已经把您拉黑，消息无法送达。";
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
    }
    
}

- (void)doAfterOperationOnMain
{
    if (self.remindMessageArray != nil && [self.remindMessageArray count]>0) {
        [self.imService notifyReceiveNewMessages:self.remindMessageArray];
    }
}

@end
