//
//  ConversationDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "ConversationDao.h"

@implementation ConversationDao

- (Conversation *)loadWithConversationId:(NSInteger)conversationId
{
    Conversation *conversation = [self.identityScope objectByKey:@(conversationId) lock:YES];
    if (! conversation)
    {
        NSString *queryString = [NSString stringWithFormat:@"rowid=%ld and status=0", (long)conversationId];
        conversation = [self.dbHelper  searchSingle:[Conversation class] where:queryString orderBy:nil];
        [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[Conversation class]];
        
        if (conversation)
        {
            [self attachEntityKey:@(conversation.rowid) entity:conversation lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[Conversation class]];
    }
    return conversation;
}

- (Conversation *)loadWithOwnerId:(int64_t)ownerId
                        ownerRole:(IMUserRole)ownerRole
               otherUserOrGroupId:(int64_t)userId
                         userRole:(IMUserRole)otherRserRole
                         chatType:(IMChatType)chatType
{
    Conversation *conversation = [self.identityScope objectByCondition:^BOOL(id key, id item) {
        Conversation *_conv = (Conversation *)item;
        return (_conv.ownerId == ownerId &&
                _conv.ownerRole == ownerRole &&
                _conv.toId == userId &&
                _conv.chat_t == chatType);
    } lock:YES];
    
    if (! conversation)
    {
        NSString *query = @"";
        if (chatType ==  eChatType_Chat) {
            query = [NSString stringWithFormat:@" AND toRole=%ld" ,(long)otherRserRole];
        }else{
            query = @"";
        }
        NSString  *queryString = [NSString stringWithFormat:@"ownerId=%lld\
                                  AND ownerRole=%ld\
                                  AND toId=%lld %@\
                                  AND chat_t=%ld and status=0",ownerId, (long)ownerRole,userId,query,(long)chatType];
        conversation = [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[Conversation class]];
        if (conversation)
        {
            [self attachEntityKey:@(conversation.rowid) entity:conversation lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[Conversation class]];
    }
    return conversation;
}

- (void)insert:(Conversation *)conversation
{
    [self.dbHelper insertToDB:conversation];
    [self attachEntityKey:@(conversation.rowid) entity:conversation lock:YES];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"insert" class:[Conversation class]];
}

- (void)update:(Conversation *)conversation
{
    [self.dbHelper updateToDB:conversation where:nil];
    [self attachEntityKey:@(conversation.rowid) entity:conversation lock:YES];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"update" class:[Conversation class]];
}

- (NSArray *)loadAllWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole
{
    NSString *queryString  = [NSString stringWithFormat:@"ownerId=%lld \
                              AND ownerRole=%ld and status=0  ORDER BY lastMessageId DESC",ownerId,(long)ownerRole];
    NSArray *array = [self.dbHelper search:[Conversation class] where:queryString orderBy:nil offset:0 count:0];
    [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[Conversation class]];
    [self.identityScope lock];
    for (NSInteger index = 0; index < array.count; ++ index) {
        Conversation *_conv = [array objectAtIndex:index];
        
        [self attachEntityKey:@(_conv.rowid) entity:_conv lock:NO];
    }
    [self.identityScope unlock];
    return array;
}
@end
