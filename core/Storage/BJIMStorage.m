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
//#import "TeacherContacts.h"
//#import "StudentContacts.h"
//#import "InstitutionContacts.h"
#import "Contacts.h"
#import "RecentContacts.h"


#define IM_STRAGE_NAME @"bjhl-hermes-db"
#define IM_STRAGE_NAME_INFO @"bjhl-hermes-info-db"

const NSString *const IMTeacherContactTableName  = @"TEACHERCONTACTS";
const NSString *const IMStudentContactTabaleName = @"STUDENTCONTACTS";
const NSString *const IMInstitutionContactTableName     = @"INSTITUTIONCONTACTS";

@implementation BJIMStorage

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.dbHelper = [[LKDBHelper alloc] initWithDBName:IM_STRAGE_NAME];
        self.dbHelperInfo = [[LKDBHelper alloc] initWithDBName:IM_STRAGE_NAME_INFO];
        
        self.userDao = [[UserDao alloc] init];
        self.userDao.dbHelper = self.dbHelperInfo;
        self.userDao.imStroage = self;
        
        self.contactsDao = [[ContactsDao alloc] initWithDBHelper:self.dbHelperInfo];
        self.contactsDao.imStroage = self;
        
        
//        self.institutionDao = [[InstitutionContactDao alloc] init];
//        self.institutionDao.dbHelper = self.dbHelperInfo;
//        self.institutionDao.imStroage = self;
//        
//        self.studentDao = [[StudentContactDao alloc] init];
//        self.studentDao.dbHelper = self.dbHelperInfo;
//        self.studentDao.imStroage = self;
//        
//        self.teacherDao = [[TeacherContactDao alloc] init];
//        self.teacherDao.dbHelper = self.dbHelperInfo;
//        self.teacherDao.imStroage = self;
        
        self.groupDao = [[GroupDao alloc] init];
        self.groupDao.dbHelper = self.dbHelperInfo;
        self.groupDao.imStroage = self;
        
        self.groupMemberDao = [[GroupMemberDao alloc] init];
        self.groupMemberDao.dbHelper = self.dbHelperInfo;
        self.groupMemberDao.imStroage = self;
        
        self.messageDao = [[IMMessageDao alloc] init];
        self.messageDao.dbHelper = self.dbHelper;
        self.messageDao.imStroage = self;
        
        self.conversationDao = [[ConversationDao alloc] init];
        self.conversationDao.dbHelper = self.dbHelper;
        self.conversationDao.imStroage = self;
    }
    return self;
}

- (void)clearSession
{
    [self.userDao clear];
//    [self.institutionDao clear];
//    [self.studentDao clear];
//    [self.teacherDao clear];
    [self.contactsDao clear];
    [self.groupDao clear];
    [self.groupMemberDao clear];
    [self.messageDao clear];
    [self.conversationDao clear];
}

#pragma mark conversation
//计算未读条数 免打扰的不计数
- (long)sumOfAllConversationUnReadNumOwnerId:(int64_t)ownerId userRole:(IMUserRole)userRole
{
    __block NSInteger num = 0;
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *query = [NSString stringWithFormat:@"select sum(unReadNum) from CONVERSATION where ownerId=%lld and ownerRole=%ld and relation=%ld and status=0", ownerId, (long)userRole, (long)eConverastion_Relation_Normal];
        FMResultSet *result = [db executeQuery: query];
        while ([result next])
        {
            num = [result longForColumnIndex:0];
        }
        [result close];
    }];
    return num;
}

//#pragma mark contact
//- (BOOL)hasContactOwner:(User *)owner contact:(User *)contact
//{
//    if (owner.userRole == eUserRole_Institution)
//    {
//        return ([self.institutionDao loadContactId:contact.userId contactRole:contact.userRole owner:owner] != nil);
//    }
//    else if (owner.userRole == eUserRole_Student)
//    {
//        return ([self.studentDao loadContactId:contact.userId contactRole:contact.userRole owner:owner] != nil);
//    }
//    else if (owner.userRole == eUserRole_Teacher)
//    {
//        return ([self.teacherDao loadContactId:contact.userId contactRole:contact.userRole owner:owner] != nil);
//    }
//    return NO;
//}
//
//- (void)insertOrUpdateContactOwner:(User *)owner contact:(User *)contact
//{
//    if (owner.userRole == eUserRole_Teacher)
//    {
//        TeacherContacts *relation = [[TeacherContacts alloc] init];
//        relation.userId = owner.userId;
//        relation.contactId = contact.userId;
//        relation.contactRole = contact.userRole;
//        relation.createTime = [[NSDate date] timeIntervalSince1970];
//        relation.remarkName = contact.remarkName;
//        relation.remarkHeader = contact.remarkHeader;
//        [self.teacherDao insertOrUpdateContact:relation owner:owner];
//    }
//    else if (owner.userRole == eUserRole_Student)
//    {
//        StudentContacts *relation = [[StudentContacts alloc] init];
//        relation.userId = owner.userId;
//        relation.contactId = contact.userId;
//        relation.contactRole = contact.userRole;
//        relation.createTime = [[NSDate date] timeIntervalSince1970];
//        relation.remarkName = contact.remarkName;
//        relation.remarkHeader = contact.remarkHeader;
//        [self.studentDao insertOrUpdateContact:relation owner:owner];
//    }
//    else if (owner.userRole == eUserRole_Institution)
//    {
//        InstitutionContacts *relation = [[InstitutionContacts alloc] init];
//        relation.userId = owner.userId;
//        relation.contactId = contact.userId;
//        relation.contactRole = contact.userRole;
//        relation.createTime = [[NSDate date] timeIntervalSince1970];
//        relation.remarkName = contact.remarkName;
//        relation.remarkHeader = contact.remarkHeader;
//        [self.institutionDao insertOrUpdateContact:relation owner:owner];
//    }
//}

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

//- (void)deleteMyContactWithUser:(User*)user
//{
//    if (user.userRole == eUserRole_Teacher)
//    {
//        [self.teacherDao deleteAllContacts:user];
//    }
//    else if (user.userRole == eUserRole_Student)
//    {
//        [self.studentDao deleteAllContacts:user];
//    }
//    else if(user.userRole == eUserRole_Institution)
//    {
//        [self.institutionDao deleteAllContacts:user];
//    }
//}

//- (void)deleteContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
//{
//    if (owner.userRole == eUserRole_Teacher)
//    {
//        [self.teacherDao deleteContactId:contactId contactRole:contactRole owner:owner];
//    }
//    else if (owner.userRole == eUserRole_Student)
//    {
//        [self.studentDao deleteContactId:contactId contactRole:contactRole owner:owner];
//    }
//    else if(owner.userRole == eUserRole_Institution)
//    {
//        [self.institutionDao deleteContactId:contactId contactRole:contactRole owner:owner];
//    }
//}

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
    [self.dbHelperInfo updateToDB:[Group class] set:[NSString stringWithFormat:@" lastMessageId='%@'", msgId] where:[NSString stringWithFormat:@" lastMessageId='%@'", errMsgId]];
    
    [self.dbHelperInfo updateToDB:[Group class] set:[NSString stringWithFormat:@" startMessageId='%@'", msgId] where:[NSString stringWithFormat:@" startMessageId='%@'", errMsgId]];
    [self.dbHelperInfo updateToDB:[Group class] set:[NSString stringWithFormat:@" endMessageId='%@'", msgId] where:[NSString stringWithFormat:@" endMessageId='%@'", errMsgId]];
}

/**
 *  删除3.0 中插入的关注消息
 */
- (void)deleteDirtyMessages
{
    // 本地未发出的通知类型消息都是 关注 插入的消息。 全部删掉
    NSString *where = [NSString stringWithFormat:@" msgId like '%%.%%' and msg_t = %ld", eMessageType_NOTIFICATION];
    [self.dbHelper deleteWithClass:[IMMessage class] where:where];
}


- (NSString *)nextFakeMessageId
{
    NSString *maxMessageId = [self.messageDao queryAllMessageMaxMsgId];
    NSString *nextMsgId = [NSString stringWithFormat:@"%015.3lf", [maxMessageId doubleValue] + 0.001];
    return nextMsgId;
}

@end
