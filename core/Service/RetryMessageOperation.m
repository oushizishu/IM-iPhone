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
    
    Conversation *conversation = [self.imService getConversationUserOrGroupId:self.message.receiver userRole:self.message.receiverRole ownerId:self.message.sender ownerRole:self.message.senderRole chat_t:self.message.chat_t];
    
    self.message.msgId = [NSString stringWithFormat:@"%015.3lf", [[self.imService.imStorage.messageDao queryAllMessageMaxMsgId] doubleValue] + 0.001];
    
    conversation.lastMessageId = self.message.msgId;
    
    [self.imService.imStorage.conversationDao update:conversation];
    [self.imService.imStorage.messageDao update:self.message];
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
