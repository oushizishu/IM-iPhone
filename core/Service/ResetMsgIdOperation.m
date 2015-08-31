//
//  ResetMsgIdOperation.m
//  Pods
//
//  Created by 杨磊 on 15/8/25.
//
//

#import "ResetMsgIdOperation.h"
#import "BJIMService.h"


@implementation ResetMsgIdOperation

- (void)doOperationOnBackground
{
    NSArray *messages = [self.imService.imStorage queryAllBugMessages];
    if ([messages count] == 0)
    {
        [[NSUserDefaults standardUserDefaults] setValue:@"ResetMsgIdOperation" forKey:@"ResetMsgIdOperation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
    
    for (NSInteger index = 0; index < [messages count]; ++ index)
    {
        IMMessage *msg = [messages objectAtIndex:index];
        NSInteger _msgId = [msg.msgId integerValue];
        NSString *msgId = [NSString stringWithFormat:@"%011ld", (long)_msgId];
        
        [self.imService.imStorage updateConversationWithErrorLastMessageId:msg.msgId newMsgId:msgId];
        [self.imService.imStorage updateGroupErrorMsgId:msg.msgId newMsgId:msgId];
        
        if ([self.imService.imStorage.messageDao loadWithMessageId:msgId])
        {
            //该消息ID 已存在. 重复消息，可以删除
            [msg deleteToDB];
            continue;
        }
        msg.msgId = msgId;
        [self.imService.imStorage.messageDao update:msg];
    }
    [[NSUserDefaults standardUserDefaults] setValue:@"ResetMsgIdOperation" forKey:@"ResetMsgIdOperation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)doAfterOperationOnMain
{}

@end
