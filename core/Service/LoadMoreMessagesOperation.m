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
@property (nonatomic, strong) NSArray *preMessages;

@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, copy) NSString *excludeIds;
@property (nonatomic, copy) NSString *endMessageId;

@end

@implementation LoadMoreMessagesOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    self.conversation.imService = self.imService;
    
    NSString *minConversationMsgId = [self.imService.imStorage.messageDao queryMinMsgIdInConversation:self.conversation.rowid];
    NSString *maxConversationMsgId = [self.imService.imStorage.messageDao queryMaxMsgIdInConversation:self.conversation.rowid];
    
    if (self.conversation.chat_t == eChatType_Chat)
    {
        //单聊，直接查询数据库

        NSString *__minMsgId = self.minMsgId == nil ? [NSString stringWithFormat:@"%015.4lf", [maxConversationMsgId doubleValue] + 0.0001] : self.minMsgId;
        self.messages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:__minMsgId];
        
        if ([self.messages count] > 0 && [[[self.messages objectAtIndex:0] msgId] doubleValue] > [minConversationMsgId doubleValue])
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
        Group *group = [self.imService.imStorage.groupDao load:self.conversation.toId];
        
        group.lastMessageId = maxConversationMsgId;
        
        if (self.minMsgId != nil && [self.minMsgId doubleValue] < [group.lastMessageId doubleValue] && [group.endMessageId doubleValue] <= [group.startMessageId doubleValue])
        {
            // 不是第一次加载，并且本地没有空洞
            self.messages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:self.minMsgId];
            
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
            NSString *__minMsgId = self.minMsgId == nil ? [NSString stringWithFormat:@"%015.4lf", [maxConversationMsgId doubleValue] + 0.0001] : self.minMsgId;
            
            self.preMessages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:__minMsgId];
            
            self.excludeIds = @"";
            // 群聊中可能包含空洞，getMsg 把可能不存在的消息拉下来
            [self.preMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IMMessage *_message = (IMMessage *)obj;
                if (_message.status != eMessageStatus_Send_Fail)
                {
                    if ([_excludeIds length] == 0) {
                        _excludeIds = [NSString stringWithFormat:@"%lld", [_message.msgId longLongValue]];
                    } else {
                        _excludeIds = [NSString stringWithFormat:@"%@,%lld", _excludeIds, [_message.msgId longLongValue]];
                    }
                    
                }
                _message.imService = self.imService;
            }];
            
            if ([self.preMessages count] > 0) {
                self.endMessageId = [[self.preMessages objectAtIndex:0] msgId];
            }
        }
        
        [self.imService.imStorage.groupDao insertOrUpdate:group];
    }
}

- (void)doAfterOperationOnMain
{
    if (self.messages)
    {
        // 本地已加载完毕， 不需要通过网络
        [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
    }
    else
    {
        
        if (self.minMsgId == nil && [self.preMessages count] > 0)
        {
            [self.imService notifyPreLoadMessages:self.preMessages conversation:self.conversation];
        }
        
        [self.imService.imEngine getMsgConversation:self.conversation.rowid
                                           minMsgId:self.minMsgId
                                            groupId:self.conversation.toId
                                             userId:0
                                         excludeIds:[self.excludeIds copy]
                                     startMessageId:self.endMessageId];
       
    }
}

@end
