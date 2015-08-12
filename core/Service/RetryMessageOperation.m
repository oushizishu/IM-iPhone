//
//  RetryMessageOperation.m
//  Pods
//
//  Created by 杨磊 on 15/8/8.
//
//

#import "RetryMessageOperation.h"

#import "Conversation.h"
#import "IMMessage.h"
#import "BJIMService.h"
#import "BJIMStorage.h"
#import "BJIMEngine.h"

@implementation RetryMessageOperation

- (void)doOperationOnBackground
{
    Conversation *conversation = [self.imService.imStorage queryConversation:self.message.sender ownerRole:self.message.senderRole otherUserOrGroupId:self.message.receiver userRole:self.message.receiverRole chatType:self.message.chat_t];
    
//    double maxConversationMsgId = [self.imService.imStorage queryMaxMsgIdInConversation:conversation.rowid];
    self.message.msgId = [self.imService.imStorage queryAllMessageMaxMsgId] + 0.001;
    conversation.lastMessageId = self.message.msgId;
    
    [self.imService.imStorage updateConversation:conversation];
    [self.imService.imStorage updateMessage:self.message];
}

- (void)doAfterOperationOnMain
{
    if (self.message.msg_t == eMessageType_IMG)
    {
        IMImgMessageBody *imgMessageBody = (IMImgMessageBody *)self.message.messageBody;
        if([imgMessageBody.url length] == 0)
        {
            [self.imService.imEngine postMessageAchive:self.message];
        }
        else
        {
            [self.imService.imEngine postMessage:self.message];
        }
    }
    else if (self.message.msg_t == eMessageType_AUDIO)
    {
        IMAudioMessageBody *audioMessageBody = (IMAudioMessageBody *)self.message.messageBody;
        if ([audioMessageBody.url length] == 0)
        {
            [self.imService.imEngine postMessageAchive:self.message];
        }
        else
        {
            [self.imService.imEngine postMessage:self.message];
        }
    }
    else
    {
        [self.imService.imEngine postMessage:self.message];
    }
    
    [self.imService notifyConversationChanged];
}

@end