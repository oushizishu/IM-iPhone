//
//  BJIMStorage.m
//  Pods
//
//  Created by 杨磊 on 15/5/14.
//
//

#import "BJIMStorage.h"
#import <LKDBHelper/LKDBHelper.h>
#import "Conversation.h"
#import "User.h"
#import "Group.h"
#import "IMMessage.h"
#import "GroupMember.h"
#import "TeacherContacts.h"
#import "StudentContacts.h"
#import "InstitutionContacts.h"
#import "RecentContacts.h"


#define IM_STRAGE_NAME @"bjhl-hermes-db"
const NSString *const IMTeacherContactTableName  = @"TEACHERCONTACTS";
const NSString *const IMStudentContactTabaleName = @"STUDENTCONTACTS";
const NSString *const IMInstitutionContactTableName     = @"INSTITUTIONCONTACTS";

#define IM_STRAGE_NAME @"bjhl-hermes-db"
#define KEY_LOAD_MESSAGE_PAGE_COUNT 30


@interface BJIMStorage()
@property (nonatomic, strong) LKDBHelper *dbHelper;


@end

@implementation BJIMStorage

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.dbHelper = [[LKDBHelper alloc] initWithDBName:IM_STRAGE_NAME];
        self.userDao = [[UserDao alloc] init];
        self.userDao.dbHelper = self.dbHelper;
        self.userDao.imStroage = self;
        
        self.institutionDao = [[InstitutionContactDao alloc] init];
        self.institutionDao.dbHelper = self.dbHelper;
        self.institutionDao.imStroage = self;
        
        self.studentDao = [[StudentContactDao alloc] init];
        self.studentDao.dbHelper = self.dbHelper;
        self.studentDao.imStroage = self;
        
        self.teacherDao = [[TeacherContactDao alloc] init];
        self.teacherDao.dbHelper = self.dbHelper;
        self.teacherDao.imStroage = self;
        
        self.groupDao = [[GroupDao alloc] init];
        self.groupDao.dbHelper = self.dbHelper;
        self.groupDao.imStroage = self;
        
        self.groupMemberDao = [[GroupMemberDao alloc] init];
        self.groupMemberDao.dbHelper = self.dbHelper;
        self.groupMemberDao.imStroage = self;
    }
    return self;
}

#pragma mark message
- (BOOL)insertMessage:(IMMessage*)message{
    return [self.dbHelper insertToDB:message];
}

- (IMMessage*)queryMessage:(NSInteger)messageRowid
{
    NSString *queryString = [NSString stringWithFormat:@"rowId=%ld", (long)messageRowid];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message;
}

- (IMMessage*)queryMessageWithMessageId:(NSString *)messageId
{
    NSString *queryString = [NSString stringWithFormat:@"msgId='%@'",messageId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message;
}

- (BOOL)updateMessage:(IMMessage*)message
{
    NSString *queryString = [NSString stringWithFormat:@"rowid=%ld",(long)message.rowid];
    return  [self.dbHelper  updateToDB:message where:queryString];
}

// 我收到的最大消息id
- (NSString *)queryChatLastMsgIdOwnerId:(int64_t)ownerId  ownerRole:(IMUserRole)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@"chat_t=0 AND receiver=%lld AND receiverRole=%ld ORDER BY msgId  DESC ",ownerId, (long)ownerRole];
    
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (NSString *)queryGroupChatLastMsgId:(int64_t)groupId withoutSender:(int64_t)sender sendRole:(NSInteger)senderRole
{
    NSString *queryString = [NSString stringWithFormat:@"receiver=%lld \
                             AND sender <> %lld \
                             ORDER BY msgId DESC ",groupId, sender];
    
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (NSString *)queryMaxMsgIdGroupChat:(int64_t)groupId
{
    NSString *queryString = [NSString stringWithFormat:@" receiver=%lld order by msgId desc", groupId];
    IMMessage *msg = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return msg.msgId;
}

- (NSArray *)queryGroupChatExcludeMsgs:(int64_t)groupId maxMsgId:(NSString *)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@"receiver=%lld and msgId>'%@' and status=%ld", groupId, maxMsgId, eMessageStatus_Send_Succ];
    NSArray *array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    return array;
}


- (NSArray *)queryChatExludeMessagesMaxMsgId:(NSString *)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@" chat_t=0 and msgId>'%@'", maxMsgId];
    NSArray *messages = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    return messages;
}

- (NSString *)queryGroupConversationMaxMsgId:(int64_t)groupId owner:(int64_t)ownerId role:(NSInteger)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@" receiver=%lld \
                             AND sender=%lld \
                             AND senderRole=%ld\
                             ORDER  BY msgId DESC", groupId, ownerId, (long)ownerRole];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (NSString *)queryMinMsgIdInConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                             ORDER BY msgId ASC ", (long)conversationId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (NSString *)queryMaxMsgIdInConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld ORDER BY msgId DESC", (long)conversationId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (NSString *)queryAllMessageMaxMsgId
{
//    NSString *queryString = [NSString stringWithFormat:@" ORDER BY msgId DESC"];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:nil orderBy:@" msgId DESC"];
    return message.msgId;
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
    return _array;
}

- (NSArray *)loadChatMessagesInConversation:(NSInteger)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                              ORDER BY msgId DESC LIMIT %d ", (long)conversationId, KEY_LOAD_MESSAGE_PAGE_COUNT];
    NSMutableArray *_array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    NSArray *__array = [[_array reverseObjectEnumerator] allObjects];
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
    return __array;
}

#pragma mark conversation
- (BOOL)insertConversation:(NSObject *)conversation
{
    NSAssert([conversation isKindOfClass:[Conversation class]], @"类型错误");
   return  [self.dbHelper insertToDB:conversation];
}

- (NSArray*)queryAllConversationOwnerId:(int64_t)ownerId
                               userRole:(IMUserRole)userRole
{
    NSString *queryString  = [NSString stringWithFormat:@"ownerId=%lld \
                                                     AND ownerRole=%ld and status=0  ORDER BY lastMessageId DESC",ownerId,(long)userRole];
    NSArray *array = [self.dbHelper search:[Conversation class] where:queryString orderBy:nil offset:0 count:0];
    array = [array count]>0?array:nil;
    return array;
}

- (Conversation*)queryConversation:(int64_t)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@"rowid=%lld and status=0",conversationId];
    return  [self.dbHelper  searchSingle:[Conversation class] where:queryString orderBy:nil];
}

- (Conversation*)queryConversation:(int64_t)ownerId
                          ownerRole:(IMUserRole)ownerRole
                otherUserOrGroupId:(int64_t)userId
                          userRole:(IMUserRole)otherRserRole
                          chatType:(IMChatType)chatType
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
    return [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
}

- (void)updateConversation:(Conversation *)conversation
{
    [self.dbHelper updateToDB:conversation where:[NSString stringWithFormat:@" rowid=%ld", (long)conversation.rowid]];
}

- (long)sumOfAllConversationUnReadNumOwnerId:(int64_t)ownerId userRole:(IMUserRole)userRole
{
    
//    NSArray *array = [self queryAllConversationOwnerId:ownerId userRole:userRole];
//    if ([array count] == 0) {
//        return 0;
//    }
//    int unRead = 0;
//    for (Conversation *conversation in array) {
//        unRead += conversation.unReadNum;
//    }
    __block NSInteger num = 0;
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *query = [NSString stringWithFormat:@"select sum(unReadNum) from CONVERSATION where ownerId=%lld and ownerRole=%ld", ownerId, (long)userRole];
        FMResultSet *result = [db executeQuery: query];
        while ([result next])
        {
            num = [result longForColumnIndex:0];
        }
    }];
    return num;
}

#pragma mark contact
- (BOOL)hasContactOwner:(User*)owner contact:(User*)contact
{
    if (owner.userRole == eUserRole_Institution)
    {
        return ([self.institutionDao loadContactId:contact.userId contactRole:contact.userRole owner:owner] != nil);
    }
    else if (owner.userRole == eUserRole_Student)
    {
        return ([self.studentDao loadContactId:contact.userId contactRole:contact.userRole owner:owner] != nil);
    }
    else if (owner.userRole == eUserRole_Teacher)
    {
        return ([self.teacherDao loadContactId:contact.userId contactRole:contact.userRole owner:owner]);
    }
    return NO;
}

- (void)insertOrUpdateContactOwner:(User*)owner contact:(User*)contact
{
    if (owner.userRole == eUserRole_Teacher)
    {
        TeacherContacts *relation = [[TeacherContacts alloc] init];
        relation.userId = owner.userId;
        relation.contactId = contact.userId;
        relation.contactRole = contact.userRole;
        relation.createTime = [[NSDate date] timeIntervalSince1970];
        relation.remarkName = contact.remarkName;
        relation.remarkHeader = contact.remarkHeader;
        [self.teacherDao insertOrUpdateContact:relation owner:owner];
    }
    else if (owner.userRole == eUserRole_Student)
    {
        StudentContacts *relation = [[StudentContacts alloc] init];
        relation.userId = owner.userId;
        relation.contactId = contact.userId;
        relation.contactRole = contact.userRole;
        relation.createTime = [[NSDate date] timeIntervalSince1970];
        relation.remarkName = contact.remarkName;
        relation.remarkHeader = contact.remarkHeader;
        [self.studentDao insertOrUpdateContact:relation owner:owner];
    }
    else if (owner.userRole == eUserRole_Institution)
    {
        InstitutionContacts *relation = [[InstitutionContacts alloc] init];
        relation.userId = owner.userId;
        relation.contactId = contact.userId;
        relation.contactRole = contact.userRole;
        relation.createTime = [[NSDate date] timeIntervalSince1970];
        relation.remarkName = contact.remarkName;
        relation.remarkHeader = contact.remarkHeader;
        [self.institutionDao insertOrUpdateContact:relation owner:owner];
    }
}

- (NSArray *)queryRecentContactsWithUserId:(int64_t)userId userRole:(IMUserRole)userRole
{
    NSString *queryString = [NSString stringWithFormat:@" userId=%lld and userRole=%ld order by updateTime desc", userId, (long)userRole];
    NSArray *array = [self.dbHelper search:[RecentContacts class] where:queryString orderBy:nil offset:0 count:0];
    
    if ([array count] == 0)return nil;
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        RecentContacts *contact = [array objectAtIndex:index];
        User *user = [self.userDao loadUser:contact.contactId role:contact.contactRole];
        user.remarkHeader = contact.remarkHeader;
        user.remarkName = contact.remarkName;
        [contacts addObject:user];
    }
    return contacts;
}

- (BOOL)checkMessageStatus{
    NSString *queryString = [NSString stringWithFormat:@"UPDATE IMMESSAGE SET status = %ld WHERE status = %ld",(long)eMessageStatus_Send_Fail,(long)eMessageStatus_Sending];
    return [self.dbHelper executeSQL:queryString arguments:nil];
}

-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId minMsgId:(NSString *)minMsgId
{
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM IMMESSAGE WHERE conversationId = %ld AND msgId<'%@' ORDER BY msgId DESC LIMIT %d", (long)conversationId, minMsgId, MESSAGE_PAGE_COUNT];
    NSArray *array = [self.dbHelper  searchWithSQL:queryString toClass:[IMMessage class]];
    
    NSArray *_array = [[array reverseObjectEnumerator] allObjects];
    
    return _array;
}

- (void)deleteMyContactWithUser:(User*)user
{
    if (user.userRole == eUserRole_Teacher)
    {
        [self.teacherDao deleteAllContacts:user];
    }
    else if (user.userRole == eUserRole_Student)
    {
        [self.studentDao deleteAllContacts:user];
    }
    else if(user.userRole == eUserRole_Institution)
    {
        [self.institutionDao deleteAllContacts:user];
    }
}

- (NSArray *)queryAllBugMessages
{
    NSString *query = [NSString stringWithFormat:@" length(msgId)<11"];
    return [self.dbHelper search:[IMMessage class] where:query orderBy:nil offset:0 count:0];
}

- (void)updateConversationWithErrorLastMessageId:(NSString *)errMsgId newMsgId:(NSString *)msgId
{
    [self.dbHelper updateToDB:[Conversation class] set:[NSString stringWithFormat:@" lastMessageId='%@'", msgId] where:[NSString stringWithFormat:@" lastMessageId='%@'", errMsgId]];
}

- (void)updateGroupErrorMsgId:(NSString *)errMsgId newMsgId:(NSString *)msgId
{
    [self.dbHelper updateToDB:[Group class] set:[NSString stringWithFormat:@" lastMessageId='%@'", msgId] where:[NSString stringWithFormat:@" lastMessageId='%@'", errMsgId]];
    
    [self.dbHelper updateToDB:[Group class] set:[NSString stringWithFormat:@" startMessageId='%@'", msgId] where:[NSString stringWithFormat:@" startMessageId='%@'", errMsgId]];
    [self.dbHelper updateToDB:[Group class] set:[NSString stringWithFormat:@" endMessageId='%@'", msgId] where:[NSString stringWithFormat:@" endMessageId='%@'", errMsgId]];
}

@end
