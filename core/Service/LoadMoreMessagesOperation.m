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
#import "IMEnvironment.h"

@interface LoadMoreMessagesOperation()

@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) NSArray *preMessages;

@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL needPreLoad;
@property (nonatomic, assign) BOOL needGetMsg;

@property (nonatomic, copy) NSString *excludeIds;
@property (nonatomic, copy) NSString *endMessageId;
@property (nonatomic, strong) Conversation *conversation;

@end

@implementation LoadMoreMessagesOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    
    IMChatType chatType = self.chatToUser == nil ? eChatType_GroupChat : eChatType_Chat;
    User *owner = [IMEnvironment shareInstance].owner;
    
    // 获取对应的 conversation
    self.conversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:(chatType==eChatType_Chat?self.chatToUser.userId:self.chatToGroup.groupId) userRole:self.chatToUser.userRole chatType:chatType];
    
    if (chatType == eChatType_Chat) {
        [self doLoadChatMessageOperation];
    } else {
        [self doLoadGroupChatMessageOperation];
    }
}

- (void)doAfterOperationOnMain
{
    IMChatType chatType = self.chatToUser == nil ? eChatType_GroupChat : eChatType_Chat;
    if (chatType == eChatType_Chat) {
        // 单聊
        if (self.needPreLoad) {
            [self.imService notifyPreLoadMessages:self.preMessages conversation:self.conversation];
        }
        
        if (self.needGetMsg) {
            [self.imService.imEngine postGetMsgLastMsgId:self.minMsgId groupId:self.chatToGroup.groupId userId:self.chatToUser.userId userRole:self.chatToUser.userRole excludeIds:self.excludeIds];
        }
        
        if (! self.needPreLoad && !self.needGetMsg) {
            [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
        }
    } else {
        // 群聊
        if (self.needPreLoad) {
            [self.imService notifyPreLoadMessages:self.preMessages conversation:self.conversation];
        }
        
        if (self.needGetMsg) {
            [self.imService.imEngine postGetMsgLastMsgId:self.minMsgId groupId:self.chatToGroup.groupId userId:self.chatToUser.userId userRole:self.chatToUser.userRole excludeIds:self.excludeIds];
        }
    }
   
}

- (void)doLoadGroupChatMessageOperation
{
    if (self.conversation == nil) {
        // 没有本地消息
        self.hasMore = YES;
        self.needPreLoad = NO;
        self.needGetMsg = YES;
    } else {
        NSString *maxConversationMsgId = [self.imService.imStorage.messageDao queryMaxMsgIdInConversation:self.conversation.rowid];
        
        NSString *__minMsgId = self.minMsgId == nil ? [NSString stringWithFormat:@"%015.4lf", [maxConversationMsgId doubleValue] + 0.0001] : self.minMsgId;
        self.preMessages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:__minMsgId];
        
        self.excludeIds = [self excutorExcludeMessageIds:self.preMessages];
        
        if (self.conversation.firstMsgId == nil || self.minMsgId == nil) {
            self.hasMore = YES;
            self.needPreLoad = YES;
            self.needGetMsg = YES;
        } else {
            self.hasMore = NO;
            self.needPreLoad = NO;
            self.needGetMsg = YES;
        }
        if (self.minMsgId == nil) self.minMsgId = __minMsgId;
    }
}

- (void)doLoadChatMessageOperation
{
    // 单聊
    if (self.conversation == nil) {
        // 本地没有两人的聊天消息记录
        //getMsg
        self.hasMore = NO;
        self.needPreLoad = NO;
        self.needGetMsg = YES;
        
        self.excludeIds = @"";
        return;
    } else {
        NSString *minConversationMsgId = [self.imService.imStorage.messageDao queryMinMsgIdInConversation:self.conversation.rowid];
        NSString *maxConversationMsgId = [self.imService.imStorage.messageDao queryMaxMsgIdInConversation:self.conversation.rowid];
        
        NSString *__minMsgId = self.minMsgId == nil ? [NSString stringWithFormat:@"%015.4lf", [maxConversationMsgId doubleValue] + 0.0001] : self.minMsgId;
        self.preMessages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:__minMsgId];
        
        // 需要排除的 msgIds
        self.excludeIds = [self excutorExcludeMessageIds:self.preMessages];
        
        if (self.conversation.firstMsgId == nil) {
            // 没有设置过 firstMsgId
            self.hasMore = YES;
            self.needPreLoad = YES;
            self.needGetMsg = YES;
            if (self.minMsgId == nil) self.minMsgId = __minMsgId;
        } else {
            if ([self.conversation.firstMsgId isEqualToString:minConversationMsgId]) {
                // 本地消息是完整的
                self.messages = self.preMessages; // 预加载出来的消息即是本次需要显示的消息
                
                if ([self.preMessages count] < MESSAGE_PAGE_COUNT) {
                    // 本地消息已经加载完毕，直接通知界面刷新
                    self.hasMore = NO;
                    self.needPreLoad = NO;
                    self.needGetMsg = NO;
                } else {
                    if ([self.preMessages count] == MESSAGE_PAGE_COUNT) {
                        if ([[[self.preMessages objectAtIndex:0] msgId] isEqualToString:self.conversation.firstMsgId]) {
                            // 本地消息加载完毕
                            self.hasMore = NO;
                            self.needPreLoad = NO;
                            self.needGetMsg = NO;
                        } else {
                            // 本次加载已满， 但是还有更多消息没有加载出来
                            self.hasMore = YES;
                            self.needPreLoad = NO;
                            self.needGetMsg = NO;
                        }
                    }
                }
            } else {
                // 本地消息是不完整的
                if ([self.preMessages count] == MESSAGE_PAGE_COUNT) {
                    // 本次已加载满
                    self.hasMore = YES;
                    self.needPreLoad = NO;
                    self.needGetMsg = NO;
                    self.messages = self.preMessages; // 预加载消息既是需要显示的消息
                } else {
                    self.hasMore = YES;
                    self.needPreLoad = NO;
                    self.needGetMsg = YES; //走 getMsg
                    if (self.minMsgId == nil) self.minMsgId = __minMsgId;
                }
            }
        }
    }
}

- (NSString *)excutorExcludeMessageIds:(NSArray *)messages {
    __block NSString *excludeIds = @"";
    // 群聊中可能包含空洞，getMsg 把可能不存在的消息拉下来
    [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IMMessage *_message = (IMMessage *)obj;
        if (_message.status != eMessageStatus_Send_Fail)
        {
            if ([excludeIds length] == 0) {
                excludeIds = [NSString stringWithFormat:@"%lld", [_message.msgId longLongValue]];
            } else {
                excludeIds = [NSString stringWithFormat:@"%@,%lld", excludeIds, [_message.msgId longLongValue]];
            }
            
        }
        _message.imService = self.imService;
    }];
    return excludeIds;
}

@end
