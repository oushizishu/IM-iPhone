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

@implementation HandlePostMessageSuccOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    
    self.message.status = eMessageStatus_Send_Succ;
    if (self.message.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService.imStorage queryGroupWithGroupId:self.message.receiver];
        group.lastMessageId = self.model.msgId;
        group.endMessageId = self.model.msgId;
        
        [self.imService.imStorage updateGroup:group];
    }
    
    self.message.msgId = self.model.msgId;
    self.message.createAt = self.model.createAt;
    
    [self.imService.imStorage updateMessage:self.message];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyDeliverMessage:self.message errorCode:RESULT_CODE_SUCC error:nil];
}
@end
