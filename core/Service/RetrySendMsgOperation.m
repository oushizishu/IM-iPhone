//
//  RetrySendMsgOperation.m
//  Pods
//
//  Created by 彭碧 on 15/7/21.
//
//

#import "RetrySendMsgOperation.h"
#import "IMMessage.h"
#import "Conversation.h"
#import "BJIMService.h"
@implementation RetrySendMsgOperation

- (void)doOperationOnBackground
{
    Conversation *conversation = self.message.conversation;
//    [conversation removeMessage:message];
//  [conversation addMessage:message];
    [conversation setLastMsgRowId:self.message.msgId];
//    [conversation update];
    int64_t conversationId = conversation.ownerId;
}

- (void)doAfterOperationOnMain
{
    [self.imService.imEngine postMessage:self.message];
}
@end