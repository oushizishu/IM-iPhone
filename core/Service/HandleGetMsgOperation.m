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
#import "IMMessage+DB.h"

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
    
    self.conversation = [self.imService.imStorage.conversationDao loadWithConversationId:self.conversationId];
    
    if (self.conversation == nil) return;
    
    self.conversation.imService = self.imService;
    if (self.conversation.chat_t == eChatType_GroupChat)
    {
        Group *group = [self.imService.imStorage.groupDao load:self.conversation.toId];
        
        NSString *__minMsgId = self.minMsgId == nil ? [NSString stringWithFormat:@"%015.4lf", [group.lastMessageId doubleValue] + 0.0001] : self.minMsgId;
        self.messages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversationId minMsgId:__minMsgId];
        
        NSString *minConversationMsgId = [self.imService.imStorage.messageDao queryMinMsgIdInConversation:self.conversationId];
        if (self.model == nil)
        {
            //getMsg 失败. 只从本地加载更多数据
            
            if ([self.messages count] > 0 && ([[[self.messages objectAtIndex:0] msgId] doubleValue] > [minConversationMsgId doubleValue]))
            {
                self.hasMore = YES;
            }
        }
        else
        {
            group.endMessageId = self.endMessageId;
            
            NSArray *list = [self.imService.imStorage.messageDao loadMoreMessagesConversation:self.conversationId minMsgId:group.startMessageId maxMsgId:group.endMessageId];
            
            if ([list count] == 0)
            {
                // 没有空洞了
                group.endMessageId = group.lastMessageId;
                group.startMessageId = group.lastMessageId;
                self.hasMore = NO;
                [self.imService.imStorage.groupDao insertOrUpdate:group];
            }
            else
            { // 还存在空洞
                self.hasMore = YES;
            }
        }
    }
    
    [self.messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IMMessage *__message = (IMMessage *)obj;
        __message.imService = self.imService;
    }];

}

- (void)doAfterOperationOnMain
{
    [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
}
@end
