//
//  IMMessageDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "IMBaseDao.h"
#import "IMMessage.h"

@interface IMMessageDao : IMBaseDao

- (IMMessage *)loadWithRowId:(NSInteger)rowId;
- (IMMessage *)loadWithMessageId:(NSString *)messageId;

- (void)insert:(IMMessage *)message;
- (void)update:(IMMessage *)message;

// 我收到的最大消息id
- (NSString *)queryChatLastMsgIdOwnerId:(int64_t)ownerId ownerRole:(IMUserRole)ownerRole;
- (NSString *)queryGroupChatLastMsgId:(int64_t)groupId withoutSender:(int64_t)sender sendRole:(NSInteger)senderRole;
- (NSString *)queryMaxMsgIdGroupChat:(int64_t)groupId;

// 群组会话最大的消息id
- (NSString *)queryGroupConversationMaxMsgId:(int64_t)groupId owner:(int64_t)ownerId role:(NSInteger)ownerRole;
// 查询会话的最小 msgId
- (NSString *)queryMinMsgIdInConversation:(NSInteger)conversationId;
// 查询会话最大的 msgId
- (NSString *)queryMaxMsgIdInConversation:(NSInteger)conversationId;
// 查询会话中特定sign值的msgId
- (NSString *)querySignMsgIdInConversation:(NSInteger)conversationId withSing:(NSString *)sign;
- (NSString *)queryAllMessageMaxMsgId;

//删除会话所有消息
- (void)deleteAllMessageInConversation:(NSInteger)conversationId;

- (NSArray *)loadChatMessagesInConversation:(NSInteger)conversationId;
- (NSArray *)loadGroupChatMessages:(Group *)group inConversation:(NSInteger)conversationId;
- (NSArray *)queryChatExludeMessagesMaxMsgId:(NSString *)maxMsgId;
- (NSArray *)queryGroupChatExcludeMsgs:(int64_t)groupId maxMsgId:(NSString *)maxMsgId;
// 根据 id 区间查询 messages
- (NSArray *)loadMoreMessagesConversation:(NSInteger)conversationId
                                 minMsgId:(NSString *)minMsgId
                                 maxMsgId:(NSString *)maxMsgId;

-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId
                                      minMsgId:(NSString *)minMsgId;

@end
