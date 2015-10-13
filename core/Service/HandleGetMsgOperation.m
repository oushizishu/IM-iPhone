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
#import "IMEnvironment.h"

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
    
    IMChatType chatType = self.groupId > 0 ? eChatType_GroupChat : eChatType_Chat;
    User *owner = [IMEnvironment shareInstance].owner;
    
    self.conversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:chatType == eChatType_Chat?self.userId : self.groupId userRole:self.userRole chatType:chatType];
    self.conversation.imService = self.imService;
    
    NSString *__minMsgId = self.minMsgId == nil ? [self.imService.imStorage.messageDao queryMaxMsgIdInConversation:self.conversation.rowid] : self.minMsgId;
    if (self.model != nil) {
        self.conversation.firstMsgId = self.model.info.firstMsgId;
        [self.imService.imStorage.conversationDao update:self.conversation];
    }
    
    self.messages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:__minMsgId];
    
    if ([self.messages count] == 0) {
        self.hasMore = NO;
    } else if ([self.messages count] > 0 && [[[self.messages objectAtIndex:0] msgId] isEqualToString:self.conversation.firstMsgId]) {
        self.hasMore = NO;
    } else {
        self.hasMore = YES;
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
