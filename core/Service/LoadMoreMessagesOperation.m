//
//  LoadMoreMessagesOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "LoadMoreMessagesOperation.h"

#import "BJIMService.h"
#import "Conversation+DB.h"
#import "Group.h"
#import "IMMessage+DB.h"

@interface LoadMoreMessagesOperation()

@property (nonatomic, strong) NSArray *messages;

@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, copy) NSMutableString *excludeIds;

@end

@implementation LoadMoreMessagesOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    self.conversation.imService = self.imService;
    
    double minConversationMsgId = [self.imService.imStorage queryMinMsgIdInConversation:self.conversation.rowid];
    if (self.conversation.chat_t == eChatType_Chat)
    {
        //单聊，直接查询数据库
        self.messages = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId];
        
        if ([self.messages count] == 0) {
            self.hasMore = NO;
        }
        else
        {
            if ([[self.messages objectAtIndex:0] msgId] > minConversationMsgId)
            {
                self.hasMore = YES;
            }
        }
    }
    else
    {
        Group *group = [self.imService getGroup:self.conversation.toId];
        
        if ([self.messages count] > 0)
        {
            self.minMsgId = [[self.messages objectAtIndex:0] msgId];
        }
        
        NSArray *list = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId];
        if (group.endMessageId <= group.startMessageId && group.endMessageId != 0)
        {
            //不需要走网络， 本地已有完整的消息数据
            group.endMessageId = group.lastMessageId;
            group.startMessageId = group.lastMessageId;
            
            self.messages = list;
            [self.imService.imStorage updateGroup:group];
            
            if ([self.messages count] == 0)
            {
                self.hasMore = NO;
            }
            else
            {
                if([[self.messages objectAtIndex:0] msgId] > minConversationMsgId)
                {
                    self.hasMore = YES;
                }
            }
        }
        else
        {
            self.excludeIds = [[NSMutableString alloc] init];
            // 群聊中可能包含空洞，getMsg 把可能不存在的消息拉下来
            [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IMMessage *_message = (IMMessage *)obj;
                if (_message.status != eMessageStatus_Send_Fail)
                {
                    [self.excludeIds appendFormat:@"%lld,", (int64_t)_message.msgId];
                }
            }];
        
        }
        
    }
}

- (void)doAfterOperationOnMain
{
    if (self.messages)
    {
        [self.messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IMMessage *_message = (IMMessage *)obj;
            _message.imService = _imService;
        }];
        
        [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
    }
    else
    {
        [self.imService.imEngine getMsgConversation:self.conversation.rowid minMsgId:self.minMsgId groupId:self.conversation.toId userId:0 excludeIds:self.excludeIds];
    }
}

@end
