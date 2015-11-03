//
//  ConversationDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "ConversationDao.h"
#import "IMEnvironment.h"

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
                                  AND chat_t=%ld",ownerId, (long)ownerRole,userId,query,(long)chatType];
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

- (void)setConversationRelation:(Conversation*)conversation withRelation:(CONVERSATION_RELATION)relation
{
    if (conversation.relation != relation) {
        conversation.relation = relation;
        [self update:conversation];
        
        Conversation *strangerConversation = [self loadWithOwnerId:conversation.ownerId ownerRole:conversation.ownerRole otherUserOrGroupId:USER_STRANGER userRole:eUserRole_Stanger chatType:eChatType_Chat];
        if (strangerConversation) {
            NSString *maxMsgId = [self queryStrangerConversationsMaxMsgId:conversation.ownerId ownerRole:conversation.ownerRole];
            if (! [strangerConversation.lastMessageId isEqualToString:maxMsgId]) {
                strangerConversation.lastMessageId = maxMsgId;
            }

            NSInteger count =[self countOfStrangerCovnersationAndUnreadNumNotZero:conversation.ownerId userRole:conversation.ownerRole];
            if (count != strangerConversation.unReadNum) {
                strangerConversation.status = 0;
            }

            strangerConversation.unReadNum = count;
            [self update:strangerConversation];
        }
    }
}

- (NSArray *)loadAllWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole
{
    NSString *queryString  = [NSString stringWithFormat:@"ownerId=%lld \
                              AND ownerRole=%ld and status=0 and relation<>%ld ORDER BY lastMessageId DESC",ownerId,(long)ownerRole, eConversation_Relation_Stranger];
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

- (NSArray *)loadAllStrangerWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole
{
    NSString *queryString  = [NSString stringWithFormat:@"ownerId=%lld \
                              AND ownerRole=%ld and status=0 and relation=%ld ORDER BY lastMessageId DESC",ownerId,(long)ownerRole, (long)eConversation_Relation_Stranger];
    
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

- (NSInteger)countOfStrangerCovnersationAndUnreadNumNotZero:(int64_t)ownerId userRole:(IMUserRole)ownerRole
{
    __block NSInteger count = 0;
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"select count(*) from CONVERSATION where ownerId=%lld \
                         AND ownerRole=%ld and status=0 and relation=%ld and unReadNum>0", ownerId, (long)ownerRole, (long)eConversation_Relation_Stranger];
        FMResultSet *set = [db executeQuery:sql];
        if ([set next]) {
            count = [set longForColumnIndex:0];
        }
        [set close];
    }];
    return count;
}


- (NSString *)queryStrangerConversationsMaxMsgId:(int64_t)ownerId ownerRole:(IMUserRole)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@" ownerId=%lld and ownerRole=%ld and relation=%ld order by lastMessageId desc ", ownerId, ownerRole, eConversation_Relation_Stranger];
    
    Conversation *conversation = [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
    if (conversation) {
        [self attachEntityKey:@(conversation.rowid) entity:conversation lock:YES];
    }
    return conversation.lastMessageId;
}

- (NSInteger)sumOfAllUnReadNumBeenHiden:(User *)owner
{
    __block NSInteger count = 0;
    NSString *query = [NSString stringWithFormat:@"select sum(unReadNum) from CONVERSATION where ownerId=%lld and ownerRole=%ld and (relation=%ld or toId=%ld or toId=%ld)", owner.userId, (long)owner.userRole, (long)eConversation_Relation_Group_Closed, (long)USER_STRANGER, (long)USER_FRESH_FANS];
    [self.dbHelper executeDB:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:query];
        if ([set next]) {
            count = [set longForColumnIndex:0];
        }
        [set close];
    }];
    return count;
}
@end
