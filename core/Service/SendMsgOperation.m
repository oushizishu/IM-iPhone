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
    Conversation *conversation = self.message.conversation;
    if (conversation == nil)
    {
        //TODO query conversation
    }
    
    if (conversation == nil)
    {
        conversation = [[Conversation alloc] init];
//        conversation.ownerId = [IMEnvironment shareInstance].owner.userId;
//        conversation.ownerRole = [IMEnvironment shareInstance].owner.userRole;
//        conversation.toId = self.message.receiver;
//        conversation.toRole = self.message.receiverRole;
//        conversation.chat_t = self.message.chat_t;
        conversation.ownerId = [IMEnvironment shareInstance].owner.userId;
        conversation.ownerRole = [IMEnvironment shareInstance].owner.userRole;
        conversation.toId = self.message.receiver;
        conversation.toRole = self.message.receiverRole;
        conversation.chat_t = self.message.chat_t;
        // insert conversation
    }
     
}

- (void)doAfterOperationOnMain
{
    [self.imService.imEngine postMessage:self.message];
}

@end
