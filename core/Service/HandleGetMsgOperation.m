//
//  HandleGetMsgOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "HandleGetMsgOperation.h"
#import "Conversation+DB.h"
#import "BJIMService.h"
#import "Group.h"

@interface HandleGetMsgOperation()

@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, assign) BOOL hasMore;

@end

@implementation HandleGetMsgOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    if (self.model) {
        [super doOperationOnBackground];
    }
    
    self.conversation = [self.imService.imStorage queryConversation:self.conversationId];
    
    if (self.conversation == nil) return;
    
    self.conversation.imService = self.imService;
    if (self.conversation.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.conversation chatToGroup];
        if (self.model && [self.model.msgs count] > 0)
        {
            NSArray *list = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversationId minMsgId:self.minMsgId];
            if ([list count] > 0)
            {
                group.endMessageId = [[list objectAtIndex:0] msgId];
            }
            
            if (group.startMessageId == 0)
            {
                list = [self.imService.imStorage loadMoreMessagesConversation:self.conversationId minMsgId:group.startMessageId maxMsgId:group.endMessageId];
                if ([list count] == 0)
                {
                    // 已经拉到头了
                    group.endMessageId = group.lastMessageId;
                    group.startMessageId = group.lastMessageId;
                }
            }
            [self.imService.imStorage updateGroup:group];
        }
        
        if (group.endMessageId <= group.startMessageId && group.startMessageId != 0)
        {
            //没有空洞
            self.messages = [self.imService.imStorage loadMoreMessageWithConversationId:self.conversationId minMsgId:self.minMsgId];
            double minConversationMsgId = [self.imService.imStorage queryMinMsgIdInConversation:self.conversationId];
            if ([self.messages count] == 0)
            {
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
            // 还存在空洞
            self.messages = [self.imService.imStorage loadMoreMessagesConversation:self.conversationId minMsgId:group.endMessageId maxMsgId:self.minMsgId];
            self.hasMore = YES;
        }
    }

}

- (void)doAfterOperationOnMain
{
    [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
}
@end
