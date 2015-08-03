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
@property (nonatomic, copy) NSString *excludeIds;
@property (nonatomic, assign) double_t newEndMessageId;

@end

@implementation LoadMoreMessagesOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    self.conversation.imService = self.imService;
    
    double minConversationMsgId = [self.imService.imStorage queryMinMsgIdInConversation:self.conversation.rowid];
    double maxConversationMsgId = [self.imService.imStorage queryMaxMsgIdInConversation:self.conversation.rowid];
    if (self.minMsgId == 0) self.minMsgId = maxConversationMsgId;
    
    if (self.conversation.chat_t == eChatType_Chat)
    {
        //单聊，直接查询数据库
        if (self.minMsgId == maxConversationMsgId)
        {
            self.messages = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId + 0.0001];
        }
        else
        {
        self.messages = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId];
        }
        
        if ([self.messages count] > 0 && [[self.messages objectAtIndex:0] msgId] > minConversationMsgId)
        {
            self.hasMore = YES;
        }
        
        [self.messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IMMessage *_message = (IMMessage *)obj;
            _message.imService = _imService;
        }];
    }
    else
    { // 群消息必须走一次 getMsg
        Group *group = [self.imService getGroup:self.conversation.toId];
        
        group.lastMessageId = maxConversationMsgId;
        
        if (self.minMsgId < group.lastMessageId && group.endMessageId <= group.startMessageId)
        {
            // 不是第一次加载，并且本地没有空洞
            self.messages = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId];
            
            if ([self.messages count] > 0 && [[self.messages objectAtIndex:0] msgId] > minConversationMsgId)
            {
                self.hasMore = YES;
            }
            [self.messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IMMessage *_message = (IMMessage *)obj;
                _message.imService = _imService;
            }];
        }
        else
        {
            NSArray *list = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId == maxConversationMsgId ? self.minMsgId + 0.0001 : self.minMsgId];
            
            self.excludeIds = @"";
            // 群聊中可能包含空洞，getMsg 把可能不存在的消息拉下来
            [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IMMessage *_message = (IMMessage *)obj;
                if (_message.status != eMessageStatus_Send_Fail)
                {
                    if ([_excludeIds length] == 0) {
                        _excludeIds = [NSString stringWithFormat:@"%lld", (int64_t)_message.msgId];
                    } else {
                        _excludeIds = [NSString stringWithFormat:@"%@,%lld", _excludeIds, (int64_t)_message.msgId];
                    }
                    
                }
            }];
            
            if ([list count] > 0) {
                self.newEndMessageId = [[list objectAtIndex:0] msgId];
            }
        }
        
        [self.imService.imStorage updateGroup:group];
    }
}

- (void)doAfterOperationOnMain
{
    if (self.messages)
    {
        [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
    }
    else
    {
        [self.imService.imEngine getMsgConversation:self.conversation.rowid minMsgId:self.minMsgId groupId:self.conversation.toId userId:0 excludeIds:self.excludeIds startMessageId:self.newEndMessageId];
    }
}

@end
