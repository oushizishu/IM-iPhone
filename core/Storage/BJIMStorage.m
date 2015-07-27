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
        
    }
    return self;
}

#pragma mark User表
- (User*)queryUser:(int64_t)userId userRole:(NSInteger)userRole
{
   User *user = [self.dbHelper searchSingle:[User class] where:[NSString stringWithFormat:@"userId=%lld AND userRole=%ld",userId,userRole] orderBy:nil];
   return user;
}

- (BOOL)insertOrUpdateUser:(User *)user
{
    BOOL value = NO;
    User *result = [self queryUser:user.userId userRole:user.userRole];
    if (!result) {
       value = [self.dbHelper  insertToDB:user];
    }else{
       value =[self.dbHelper updateToDB:user where:[NSString stringWithFormat:@"userId=%lld and userRole=%ld",user.userId, user.userRole]];
    }
    return value;
}

#pragma mark group 


- (Group*)queryGroup:(Group*)group
{
   return  [self.dbHelper searchSingle:[group class] where:[NSString stringWithFormat:@"groupId = %lld",group.groupId] orderBy:nil];
}

- (BOOL)insertOrUpdateGroup:(Group*)group
{
    BOOL value = NO;
    Group *result = [self queryGroup:group];
    if (!result) {
        value = [self.dbHelper  insertToDB:group];
    }else{
        [self updateGroup:group];
    }
    return value;
 
}

- (void)updateGroup:(Group*)group
{
    [self.dbHelper updateToDB:group where:[NSString stringWithFormat:@"groupId=%lld",group.groupId]];;
}

- (NSArray *)queryGroupsWithUser:(User *)user
{
    NSString *queryGroupMember = [NSString stringWithFormat:@" userId=%lld \
                                   AND userRole=%ld", user.userId, user.userRole];
    NSArray *groupMembers = [self.dbHelper search:[GroupMember class] where:queryGroupMember orderBy:nil offset:0 count:0];
    if ([groupMembers count] == 0) return nil;
    
    NSMutableArray *groups = [[NSMutableArray alloc] initWithCapacity:[groupMembers count]];
    
    for (NSInteger index = 0; index < [groupMembers count]; ++ index) {
        GroupMember *member = [groupMembers objectAtIndex:index];
        Group *group = [self queryGroupWithGroupId:member.groupId];
        if (group == nil) continue;
        
        [groups addObject:group];
    }
    return groups;
}

#pragma mark message 
- (BOOL)insertMessage:(IMMessage*)message{
    return [self.dbHelper insertToDB:message];
}

- (IMMessage*)queryMessage:(NSInteger)messageRowid
{
    NSString *queryString = [NSString stringWithFormat:@"rowId= %ld", messageRowid];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message;
}

- (IMMessage*)queryMessageWithMessageId:(int64_t)messageId
{
    NSString *queryString = [NSString stringWithFormat:@"msgId = %lld",messageId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message;
}

- (BOOL)updateMessage:(IMMessage*)message
{
    NSString *queryString = [NSString stringWithFormat:@"rowid=%ld",message.rowid];
    return  [self.dbHelper  updateToDB:message where:queryString];
}

// 我收到的最大消息id
- (double)queryChatLastMsgIdOwnerId:(int64_t)ownerId  ownerRole:(IMUserRole)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@"chat_t=0 AND receiver=%lld AND receiverRole=%ld ORDER BY msgId  DESC ",ownerId, ownerRole];
    
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (double)queryGroupChatLastMsgId:(int64_t)groupId withoutSender:(int64_t)sender sendRole:(NSInteger)senderRole
{
    NSString *queryString = [NSString stringWithFormat:@"receiver=%lld \
                             AND sender <> %lld \
                             AND senderRole <> %ld ORDER BY msgId ",groupId, sender, senderRole];
    
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (NSArray *)queryGroupChatExcludeMsgs:(int64_t)groupId maxMsgId:(double_t)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@"receiver=%lld and msgId>%lf", groupId, maxMsgId];
    NSArray *array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    return array;
}


- (NSArray *)queryChatExludeMessagesMaxMsgId:(double_t)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@" chat_t=0 and msgId>%lf", maxMsgId];
    NSArray *messages = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    return messages;
}

- (double)queryGroupConversationMaxMsgId:(int64_t)groupId owner:(int64_t)ownerId role:(NSInteger)ownerRole
{
    NSString *queryString = [NSString stringWithFormat:@" receiver=%lld \
                             AND sender = %lld \
                             AND senderRole = %ld\
                             ORDER  BY msgId LIMIT 1", groupId, ownerId, ownerRole];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (double)queryMinMsgIdInConversation:(int64_t)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%lld \
                             ORDER BY msgId ASC LIMIT 1", conversationId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

/**
 minMsgId 闭区间
 */
- (NSArray *)loadMoreMessagesConversation:(NSInteger)conversationId
                                 minMsgId:(double_t)minMsgId
                                 maxMsgId:(double_t)maxMsgId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld \
                                AND msgId >= %lf \
                                AND msgId < %lf \
                                ORDER BY msgId DESC", conversationId, minMsgId, maxMsgId];
    NSArray *array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    NSArray *_array = [[array reverseObjectEnumerator] allObjects];
    return _array;
}

- (NSArray *)loadChatMessagesInConversation:(int64_t)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId = %lld \
                              ORDER BY msgId DESC LIMIT %d ", conversationId, KEY_LOAD_MESSAGE_PAGE_COUNT];
    NSMutableArray *_array = [self.dbHelper search:[IMMessage class] where:queryString orderBy:nil offset:0 count:0];
    NSArray *__array = [[_array reverseObjectEnumerator] allObjects];
    return __array;
}

- (NSArray *)loadGroupChatMessages:(Group *)group inConversation:(int64_t)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@" conversationId = %lld \
                             AND msgId >= %lf \
                             AND msgId <= %lf \
                             ORDER BY msgId DESC LIMIT %d ",
                             conversationId,
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
                                                     AND ownerRole=%ld  ORDER BY lastMsgRowId DESC",ownerId,(long)userRole];
    NSArray *array = [self.dbHelper search:[Conversation class] where:queryString orderBy:nil offset:0 count:0];
    array = [array count]>0?array:nil;
    return array;
}

- (Conversation*)queryConversation:(int64_t)conversationId
{
    NSString *queryString = [NSString stringWithFormat:@"conversationId = %lld",conversationId];
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
        query = [NSString stringWithFormat:@" AND toRole = %ld" ,otherRserRole];
    }else{
        query = @"";
    }
    NSString  *queryString = [NSString stringWithFormat:@"ownerId=%lld\
                                                     AND ownerRole=%ld\
                                                     AND toId=%lld %@\
                                                     AND chat_t=%ld",ownerId, ownerRole,userId,query,chatType];
    return [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
}

- (void)updateConversation:(Conversation *)conversation
{
    [self.dbHelper updateToDB:conversation where:[NSString stringWithFormat:@" rowid=%ld", conversation.rowid]];
}

- (long)sumOfAllConversationUnReadNumOwnerId:(int64_t)ownerId userRole:(IMUserRole)userRole
{
    NSArray *array = [self queryAllConversationOwnerId:ownerId userRole:userRole];
    if ([array count] == 0) {
        return 0;
    }
    int unRead = 0;
    for (Conversation *conversation in array) {
        unRead += conversation.unReadNum;
    }
    return unRead;
}

#pragma mark contact
- (BOOL)hasContactOwner:(User*)owner contact:(User*)contact
{
    NSString *classString = nil;
    if (owner.userRole == eUserRole_Institution) {
        classString = @"InstitutionContacts";
    } else if (owner.userRole == eUserRole_Student) {
        classString = @"StudentContacts";
    } else if (owner.userRole == eUserRole_Teacher) {
        classString = @"TeacherContacts";
    }
    
    NSString *queryString = [NSString stringWithFormat:@"userId=%lld and contactId=%lld AND contactRole=%ld", owner.userId, contact.userId, contact.userRole];
    id relation  = [self.dbHelper searchSingle:NSClassFromString(classString) where:queryString orderBy:nil];
    return relation != nil;
    
}
- (BOOL)insertOrUpdateContactOwner:(User*)owner contact:(User*)contact
{
    if ([self hasContactOwner:owner contact:contact]) {
        return NO;
    }
    
    if (owner.userRole == eUserRole_Teacher) {
        TeacherContacts *relation = [[TeacherContacts alloc] init];
        relation.userId = owner.userId;
        relation.contactId = contact.userId;
        relation.contactRole = contact.userRole;
        relation.createTime = [[NSDate date] timeIntervalSince1970];
        return [self.dbHelper insertToDB:relation];
    } else if (owner.userRole == eUserRole_Student) {
        StudentContacts *relation = [[StudentContacts alloc] init];
        relation.userId = owner.userId;
        relation.contactId = contact.userId;
        relation.contactRole = contact.userRole;
        relation.createTime = [[NSDate date] timeIntervalSince1970];
        return [self.dbHelper insertToDB:relation];
    } else if (owner.userRole == eUserRole_Institution) {
        InstitutionContacts *relation = [[InstitutionContacts alloc] init];
        relation.userId = owner.userId;
        relation.contactId = contact.userId;
        relation.contactRole = contact.userRole;
        relation.createTime = [[NSDate date] timeIntervalSince1970];
        return [self.dbHelper insertToDB:relation];
    }
    return NO;
}

- (Group*)queryGroupWithGroupId:(int64_t)groupId
{
    NSString *queryString = [NSString stringWithFormat:@"groupId=%lld",groupId];
    return [self.dbHelper searchSingle:[Group class] where:queryString orderBy:nil];
}


- (NSArray*)queryContactsWithTableName:(NSString*)tableName
                                UserId:(int64_t)userId
                            contactRole:(IMUserRole)contactRole
{
    
    NSString *classString = nil;
    if ([IMStudentContactTabaleName isEqualToString:tableName]) {
       classString = @"StudentContacts";
    } else if ([IMTeacherContactTableName isEqualToString:tableName]) {
        classString = @"TeacherContacts";
    } else if ([IMInstitutionContactTableName isEqualToString:tableName]) {
        classString = @"InstitutionContacts";
    }
   
    NSString *queryString  = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE  userId=%lld AND contactRole=%ld;",tableName,userId, contactRole];
    NSArray *array = [self.dbHelper searchWithSQL:queryString toClass:NSClassFromString(classString)];
    if ([array count] == 0) {
        return nil;
    }
    NSMutableArray *users = [NSMutableArray array];
    for (id relation  in array) {
        User *user = nil;
        if ([relation isKindOfClass:[TeacherContacts class]])
        {
            user = [self queryUser:((TeacherContacts *)relation).contactId userRole:((TeacherContacts *)relation).contactRole];
        }
        else if ([relation isKindOfClass:[StudentContacts class]])
        {
            user = [self queryUser:((StudentContacts*)relation).contactId userRole:((StudentContacts *)relation).contactRole];
        }
        else if ([relation isKindOfClass:[InstitutionContacts class]])
        {
            user = [self queryUser:((InstitutionContacts*)relation).contactId userRole:((InstitutionContacts*)relation).contactRole];
        }
        if (user) {
            [users addObject:user];
        }
    }
    return users;
}

- (NSArray*)queryTeacherContactWithUserId:(int64_t)userId userRole:(IMUserRole)userRole
{
    NSString *tableName = nil;
    if (userRole == eUserRole_Teacher) return nil;
    if (userRole == eUserRole_Student) tableName = [NSString stringWithFormat:@"%@", IMStudentContactTabaleName];
    else if (userRole == eUserRole_Institution) tableName = [NSString stringWithFormat:@"%@", IMInstitutionContactTableName];

    return [self queryContactsWithTableName:tableName UserId:userId contactRole:eUserRole_Teacher];
}

- (NSArray*)queryStudentContactWithUserId:(int64_t)userId userRole:(IMUserRole)userRole
{
    NSString *tableName = nil;
    if (userRole == eUserRole_Student) return nil;
    if (userRole == eUserRole_Teacher) tableName = [NSString stringWithFormat:@"%@", IMTeacherContactTableName];
    else if (userRole == eUserRole_Institution) tableName = [NSString stringWithFormat:@"%@", IMInstitutionContactTableName];
    
 
    return [self queryContactsWithTableName:tableName UserId:userId contactRole:eUserRole_Student];
}



- (NSArray*)queryInstitutionContactWithUserId:(int64_t)userId userRole:(IMUserRole)userRole
{
    NSString *tableName = nil;
    if (userRole == eUserRole_Institution) return nil;
    if (userRole == eUserRole_Teacher) tableName = [NSString stringWithFormat:@"%@", IMTeacherContactTableName];
    else if (userRole == eUserRole_Student) tableName = [NSString stringWithFormat:@"%@", IMStudentContactTabaleName];
    return [self queryContactsWithTableName:tableName UserId:userId contactRole:eUserRole_Institution];
}

- ( BOOL)checkMessageStatus{
    NSString *queryString = [NSString stringWithFormat:@"UPDATE IMMESSAGE SET status = %ld WHERE status = %ld",eMessageStatus_Send_Fail,eMessageStatus_Sending];
    return [self.dbHelper executeSQL:queryString arguments:nil];
}

-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId minMsgId:(double)minMsgId
{
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM IMMESSAGE WHERE conversationId = %ld AND msgId < %f ORDER BY msgId DESC LIMIT %d", conversationId, minMsgId, MESSAGE_PAGE_COUNT];
    NSArray *array = [self.dbHelper  searchWithSQL:queryString toClass:[IMMessage class]];
    
    NSArray *_array = [[array reverseObjectEnumerator] allObjects];
    
    return _array;
}

- (GroupMember *)queryGroupMemberWithGroupId:(int64_t)groupId userId:(int64_t)userId userRole:(IMUserRole)userRole
{
    NSString *queryString = [NSString stringWithFormat:@" groupId=%lld AND userId=%lld and userRole=%ld",groupId, userId, userRole];
    return [self.dbHelper searchSingle:[GroupMember class] where:queryString orderBy:nil];
}


- (BOOL)insertGroupMember:(GroupMember*)groupMember{
   return [self.dbHelper insertToDB:groupMember];
}

- (double)getConversationMaxMsgId:(NSInteger)conversationId {
    
    NSString *queryString = [NSString stringWithFormat:@" conversationId=%ld ORDER BY msgId DESC", conversationId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message.msgId;
}

- (BOOL)deleteMyContactWithUser:(User*)user
{
    Class class = nil;
    if (user.userRole == eUserRole_Teacher){
        class = NSClassFromString(@"TeacherContacts");
    }else if (user.userRole == eUserRole_Student) {
        class = NSClassFromString(@"StudentContacts");
    }else if(user.userRole == eUserRole_Institution){
        class = NSClassFromString(@"InstitutionContacts");
    }
    NSString *queryString = [NSString stringWithFormat:@"userId=%lld",user.userId];
    return [self.dbHelper deleteWithClass:class where:queryString];
}

- (BOOL)deleteMyGroups:(User *)user
{
    NSString *query = [NSString stringWithFormat:@" userId=%lld and userRole=%ld", user.userId, user.userRole];
    return [self.dbHelper deleteWithClass:[GroupMember class] where:query];
}

@end
