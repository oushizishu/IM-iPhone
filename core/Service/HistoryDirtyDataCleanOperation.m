//
//  HistoryDirtyDataCleanOperation.m
//  Pods
//
//  Created by 杨磊 on 16/4/1.
//
//

#import "HistoryDirtyDataCleanOperation.h"
#import "BJIMService.h"
#import "BJIMStorage.h"
#import "IMEnvironment.h"

@implementation HistoryDirtyDataCleanOperation

- (void)doOperationOnBackground
{
    [self.imService.imStorage deleteDirtyMessages];
    NSArray *array = [self.imService.imStorage.conversationDao loadAllWithLastMessageIdAttention];
    for (Conversation *conversation in array) {
        IMMessage *message = [self.imService.imStorage.messageDao loadWithMessageId:conversation.lastMessageId];
        if (message) {
            continue;
        }
        
        // 最后一条消息可能已经被删。 找上一条消息重新设置回去
        NSString *_msgId = [self.imService.imStorage.messageDao queryMaxMsgIdInConversation:conversation.rowid];
        
        conversation.lastMessageId = _msgId;
        [self.imService.imStorage.conversationDao update:conversation];
    }
    
    // 删除陌生人会话
    User *owner = [IMEnvironment shareInstance].owner;
    Conversation *strangerConversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:-1000100 userRole:-2 chatType:eChatType_Chat];
    if (strangerConversation) {
        [self.imService.imStorage.dbHelper deleteToDB:strangerConversation];
    }
}

- (void)doAfterOperationOnMain
{
}

@end
