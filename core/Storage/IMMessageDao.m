//
//  IMMessageDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "IMMessageDao.h"
#import "BJIMConstants.h"

#define KEY_LOAD_MESSAGE_PAGE_COUNT 30

@implementation IMMessageDao

- (IMMessage *)loadWithRowId:(NSInteger)rowId
{

    IMMessage *msg = [self.identityScope objectByKey:@(rowId) lock:YES];
    
    if (! msg)
    {
        msg = [self.dbHelper searchSingle:[IMMessage class] where:[NSString stringWithFormat:@"rowid=%ld", (long)rowId] orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"rowid" class:[IMMessage class]];
        
        if (msg)
        {
            [self attachEntityKey:@(msg.rowid) entity:msg lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[IMMessage class]];
    }

    return msg;
}

- (IMMessage *)loadWithMessageId:(NSString *)messageId
{
    IMMessage *msg = [self.identityScope objectByCondition:^BOOL(id key, id item) {
        IMMessage *_msg = (IMMessage *)item;
        return ([_msg.msgId isEqualToString:messageId]);
    } lock:YES];
    
    if (!msg)
    {
        msg = [self.dbHelper searchSingle:[IMMessage class] where:[NSString stringWithFormat:@" msgId='%@'", messageId] orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" msgId " class:[IMMessage class]];
        
        if (msg)
        {
            [self attachEntityKey:@(msg.rowid) entity:msg lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[IMMessage class]];
    }
    return msg;
}

- (void)insert:(IMMessage *)message
{
    [self.dbHelper insertToDB:message];
    [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"insert" class:[IMMessage class]];
}

- (void)update:(IMMessage *)message
{
    [self.dbHelper updateToDB:message where:nil];
    [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"update" class:[IMMessage class]];
}

- (NSString *)queryChatLastMsgIdOwnerId:(int64_t)ownerId ownerRole:(IMUserRole)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@"chat_t=0 AND receiver=%lld AND receiverRole=%ld ORDER BY msgId  DESC ",ownerId, (long)ownerRole];
    
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (NSString *)queryGroupChatLastMsgId:(int64_t)groupId withoutSender:(int64_t)sender sendRole:(NSInteger)senderRole
{
    NSString *queryString = [NSString stringWithFormat:@"receiver=%lld \
                             AND sender <> %lld \
                             ORDER BY msgId DESC ",groupId, sender];
      IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (NSString *)queryMaxMsgIdGroupChat:(int64_t)groupId
{
    NSString *queryString = [NSString stringWithFormat:@" receiver=%lld order by msgId desc", groupId];
    IMMessage *msg = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    if (msg)
    {
        [self attachEntityKey:@(msg.rowid) entity:msg lock:YES];
    }
    return msg.msgId;
}


- (NSString *)queryGroupConversationMaxMsgId:(int64_t)groupId owner:(int64_t)ownerId role:(NSInteger)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@" receiver=%lld \
                             AND sender=%lld \
                             AND senderRole=%ld\
                             ORDER  BY msgId DESC", groupId, ownerId, (long)ownerRole];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (NSString *)queryMinMsgIdInConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                             ORDER BY msgId ASC ", (long)conversationId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (NSString *)queryMaxMsgIdInConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld ORDER BY msgId DESC", (long)conversationId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (NSString *)querySignMsgIdInConversation:(NSInteger)conversationId withSing:(NSString *)sign
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld AND sign='%@'", (long)conversationId,sign];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (NSString *)queryAllMessageMaxMsgId
{
    //    NSString *queryString = [NSString stringWithFormat:@" ORDER BY msgId DESC"];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:nil orderBy:@" msgId DESC"];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"msgId DESC" class:[IMMessage class]];
    if (message)
    {
        [self attachEntityKey:@(message.rowid) entity:message lock:YES];
    }
    return message.msgId;
}

- (void)deleteAllMessageInConversation:(NSInteger)conversationId
{
    /*
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"delete from IMMESSAGE where conversationid=%lld", conversationId];
        [db executeQuery:sql];
    }];
    */
    NSString *sql = [NSString stringWithFormat:@"delete from IMMESSAGE where conversationid=%ld", conversationId];
    [self.dbHelper executeSQL:sql arguments:nil];
}

- (NSArray *)loadChatMessagesInConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                             ORDER BY msgId DESC LIMIT %d ", (long)conversationId, KEY_LOAD_MESSAGE_PAGE_COUNT];
    NSMutableArray *_array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    NSArray *__array = [[_array reverseObjectEnumerator] allObjects];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    
    [self.identityScope lock];
    for (NSInteger index = 0; index < __array.count; ++ index)
    {
        IMMessage *msg = [__array objectAtIndex:index];
        [self attachEntityKey:@(msg.rowid) entity:msg lock:NO];
    }
    [self.identityScope unlock];
    return __array;
}


- (NSArray *)loadGroupChatMessages:(Group *)group inConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                             AND msgId>='%@' \
                             AND msgId<='%@' \
                             ORDER BY msgId DESC LIMIT %d ",
                             (long)conversationId,
                             group.endMessageId,
                             group.lastMessageId,
                             KEY_LOAD_MESSAGE_PAGE_COUNT];
    NSMutableArray *_array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    NSArray *__array = [[_array reverseObjectEnumerator] allObjects];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    
    [self.identityScope lock];
    for (NSInteger index = 0; index < __array.count; ++ index)
    {
        IMMessage *msg = [__array objectAtIndex:index];
        [self attachEntityKey:@(msg.rowid) entity:msg lock:NO];
    }
    [self.identityScope unlock];
    
    return __array;
}

- (NSArray *)queryChatExludeMessagesMaxMsgId:(NSString *)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@" chat_t=0 and msgId>'%@'", maxMsgId];
    NSArray *messages = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    [self.identityScope lock];
    for (NSInteger index = 0; index < messages.count; ++ index)
    {
        IMMessage *msg = [messages objectAtIndex:index];
        [self attachEntityKey:@(msg.rowid) entity:msg lock:NO];
    }
    [self.identityScope unlock];
    
    return messages;
}

- (NSArray *)queryGroupChatExcludeMsgs:(int64_t)groupId maxMsgId:(NSString *)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@"receiver=%lld and msgId>'%@' and status=%ld", groupId, maxMsgId, eMessageStatus_Send_Succ];
    NSArray *array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    [self.identityScope lock];
    for (NSInteger index = 0; index < array.count; ++ index)
    {
        IMMessage *msg = [array objectAtIndex:index];
        [self attachEntityKey:@(msg.rowid) entity:msg lock:NO];
    }
    [self.identityScope unlock];
    
    return array;
}

/**
 minMsgId 闭区间
 */
- (NSArray *)loadMoreMessagesConversation:(NSInteger)conversationId
                                 minMsgId:(NSString *)minMsgId
                                 maxMsgId:(NSString *)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                             AND msgId>='%@'\
                             AND msgId<'%@'\
                             ORDER BY msgId DESC", (long)conversationId, minMsgId, maxMsgId];
    NSArray *array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    NSArray *_array = [[array reverseObjectEnumerator] allObjects];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    [self.identityScope lock];
    for (NSInteger index = 0; index < _array.count; ++ index)
    {
        IMMessage *msg = [_array objectAtIndex:index];
        [self attachEntityKey:@(msg.rowid) entity:msg lock:NO];
    }
    [self.identityScope unlock];
    
    return _array;
}

-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId minMsgId:(NSString *)minMsgId
{
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM IMMESSAGE WHERE conversationId = %ld AND msgId<'%@' ORDER BY msgId DESC LIMIT %d", (long)conversationId, minMsgId, MESSAGE_PAGE_COUNT];
    NSArray *array = [self.dbHelper  searchWithSQL:queryString toClass:[IMMessage class]];
    
    NSArray *_array = [[array reverseObjectEnumerator] allObjects];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[IMMessage class]];
    [self.identityScope lock];
    for (NSInteger index = 0; index < _array.count; ++ index)
    {
        IMMessage *msg = [_array objectAtIndex:index];
        [self attachEntityKey:@(msg.rowid) entity:msg lock:NO];
    }
    [self.identityScope unlock];
    
    return _array;
}

@end
