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
#import "Contacts.h"

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
- (User*)queryUser:(int64_t)userId userRole:(int)userRole
{
    NSArray *array = [self.dbHelper searchSingle:[User class] where:[NSString stringWithFormat:@"userId = %lld  AND userRole = %d",userId,userRole] orderBy:nil];
    if ([array count]  == 1) {
        return array[0];
    }
    return nil;
}



- (BOOL)insertOrUpdateUser:(User *)user
{
    BOOL value = NO;
    User *result = [self queryUser:user.userId userRole:user.userRole];
    if (!result) {
       value = [self.dbHelper  insertToDB:user];
    }else{
       value =[self.dbHelper updateToDB:user where:[NSString stringWithFormat:@"userId = %hd",user.userId]];
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
    [self.dbHelper updateToDB:group where:[NSString stringWithFormat:@"groupId = %lld",group.groupId]];;
}
#pragma mark message 
- (BOOL)insertMessage:(IMMessage*)message{
    return [self.dbHelper insertToDB:message];
}

- (IMMessage*)queryMessage:(int64_t)messageId
{
//TODO
}

- (IMMessage*)queryMessageWithMessageId:(int64_t)messageId
{
    NSString *queryString = [NSString stringWithFormat:@"messageId = %lld",messageId];
    IMMessage *message = [self.dbHelper searchSingle:[IMMessage class] where:queryString orderBy:nil];
    return message;
}

- (BOOL)updateMessage:(IMMessage*)message
{
    NSString *queryString = [NSString stringWithFormat:@"messageId = %f",message.msgId];
    return  [self.dbHelper  updateToDB:message where:queryString];
}

/*
 */
- (double)queryChatLastMsgIdOwnerId:(long)ownerId  ownerRole:(IMUserRole)ownerRole
{//TODO
    NSString *queryString = [NSString stringWithFormat:@"chat_t = 0 \
                             AND sender = %ld\
                             AND senderRole = %ld\
                             AND receiver ＝ %ld\
                             AND receiverRole =  %ld ORDER BY msgId  DESC LIMIT 1",ownerId,(long)ownerRole,ownerId,ownerRole];
    
    IMMessage *message = [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
    return message.msgId;
}



- (double)queryGroupChatLastMsgId:(long)groupId
{//DOTO groupId ????
    NSString *queryString = [NSString stringWithFormat:@"receiveer = %ld ORDER BY msgId LIMIT 1",groupId];
    IMMessage *message = [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
    return message.msgId;
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
    return nil;
}

#pragma mark conversation

- (BOOL)insertConversation:(NSObject *)conversation
{
    NSAssert([conversation isKindOfClass:[Conversation class]], @"类型错误");
   return  [self.dbHelper insertToDB:conversation];
}

- (NSArray*)queryAllConversationOwnerId:(long)ownerId
                               userRole:(IMUserRole)userRole
{
    NSString *queryString  = [NSString stringWithFormat:@"ownerId = %ld \
                                                     AND userRole = %ld  ORDER BY last_msg_id DESC",ownerId,(long)userRole];
    NSArray *array = [self.dbHelper search:[Conversation class] where:queryString orderBy:nil offset:0 count:0];
    array = [array count]>0?array:nil;
    return array;
}

- (Conversation*)queryConversation:(long)conversationId{
//TODO
    NSString *queryString = [NSString stringWithFormat:@"conversationId = %ld",conversationId];
    return  [self.dbHelper  searchSingle:[Conversation class] where:queryString orderBy:nil];
}

- (Conversation*)queryConversation:(long)ownerId
                          userRole:(IMUserRole)userRole
                otherUserOrGroupId:(long)userId
                          userRole:(IMUserRole)otherRserRole
                          chatType:(IMChatType)chatType
{
    NSString *query = @"";
    if (chatType ==  eChatType_Chat) {
        query = [NSString stringWithFormat:@" AND toRole = %ld" ,(long)userRole];
    }else{
        query = @"";
    }
    NSString  *queryString = [NSString stringWithFormat:@"ownerId = %ld\
                                                     AND ownerRole = %ld\
                                                     AND toId = %ld %@\
                                                     AND chat_t = %ld",ownerId,(long)userRole,userId,query,(long)chatType];
    return [self.dbHelper searchSingle:[Conversation class] where:queryString orderBy:nil];
}

- (long)sumOfAllConversationUnReadNumOwnerId:(long)ownerId userRole:(IMUserRole)userRole
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
    NSString *queryString = [NSString stringWithFormat:@"userId = %hd AND contactRole = %ld",contact.userId,contact.userRole];
    Contacts *aContacts = [self.dbHelper searchSingle:[Contacts class] where:queryString orderBy:nil];
    return aContacts==nil?NO:YES;
    
}
- (BOOL)insertOrUpdateContactOwner:(User*)owner contact:(User*)contact
{
    if ([self hasContactOwner:owner contact:contact]) {
        return NO;
    }
    Contacts *contacts = [[Contacts alloc]init];
    contacts.userId = owner.userId;
    contacts.contactId = contacts.userId;
    contacts.contactRole = contacts.contactRole;
    contacts.createTime = [[NSDate date] timeIntervalSince1970];
   return [self.dbHelper insertToDB:contacts];
}

- (Group*)queryGroupWithGroupId:(long)groupId
{
    NSString *queryString = [NSString stringWithFormat:@"groupId = %ld",groupId];
    return [self.dbHelper searchSingle:[Group class] where:queryString orderBy:nil];
}
/*
 List<StudentContact> list = daoSession.getStudentContactDao().queryRaw(" where " +
 StudentContactDao.Properties.User_id.columnName + "=" + user_id
 +" and " +
 StudentContactDao.Properties.Contact_role.columnName+"="+ IMConstants.IMMessageUserRole.TEACHER.value(), null);
 if (list == null || list.size() == 0) return users;
 for (int i = 0; i < list.size(); ++ i) {
 StudentContact contact = list.get(i);
 User user = queryUser(contact.getContact_id(), contact.getContact_role());
 if (user != null) {
 users.add(user);
 }
 }
 */

- (NSArray*)queryTeacherContactWithUserId:(long)userId userRole:(IMUserRole)userRole
{
    NSString *queryString  = [NSString stringWithFormat:@"userId = %ld AND contactRole = %ld",userId,userRole];
    NSArray *array = [self.dbHelper  searchWithSQL:queryString toClass:[Contacts class]];
    if ([array count] == 0) {
        return nil;
    }
    NSMutableArray *users = [NSMutableArray array];
    for (Contacts *contact  in array) {
        User *user = [self queryUser:contact.contactId userRole:user.userRole];
        if (user) {
            [users addObject:user];
        }
    }
    return users;
}

- (NSArray*)queryStudentContactWithUserId:(long)userId userRole:(IMUserRole)userRole
{
    [self queryTeacherContactWithUserId:userId userRole:userRole];
}



- (NSArray*)queryInstitutionContactWithUserId:(long)userId userRole:(IMUserRole)userRole
{
    return [self queryTeacherContactWithUserId:userId userRole:userRole];
}

- ( BOOL)checkMessageStatus{
    NSString *queryString = [NSString stringWithFormat:@"UPDATE IMMESSAGE SET status = %ld WHERE status = %ld",eMessageStatus_Send_Fail,eMessageStatus_Sending];
    return [self.dbHelper executeSQL:queryString arguments:nil];
}

-  (NSArray*)loadMoreMessageWithConversationId:(long)conversationId minMsgId:(double)minMsgId
{
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM IMMESSAGE WHERE conversationId = %ld AND msgId < %f ORDER BY msgId ASC LIMIT %d",conversationId,minMsgId,MESSAGE_PAGE_COUNT];
    NSArray *array = [self.dbHelper  searchWithSQL:queryString toClass:[IMMessage class]];
    return array;
}

/*
 public GroupMember queryGroupMember(long groupId, long userId, IMConstants.IMMessageUserRole userRole) {
 List<GroupMember> members = daoSession.getGroupMemberDao().queryRaw(" where " +
 GroupMemberDao.Properties.Group_id.columnName + "=" + groupId
 + " and " +
 GroupMemberDao.Properties.User_id.columnName+"="+userId
 + " and " +
 GroupMemberDao.Properties.User_role.columnName+"="+userRole.value(), null);
 
 if (members == null || members.size() == 0) return null;
 return members.get(0);
	}
 */

- (void)queryGroupMemberWithGroupId:(long)groupId userId:(long)userId userRole:(IMUserRole)userRole
{
//TODO
    NSString *queryString = [NSString stringWithFormat:@""];
}



- (BOOL)insertGroupMember:(Group*)groupMember{
   return   [self.dbHelper insertToDB:groupMember];
}

- (double)getConversationMaxMsgId:(long)conversationId {
    NSString *queryString = [NSString stringWithFormat:@"conversationId = %ld ORDER BY msg_id DESC LIMIT 1",conversationId];
    NSArray *array = [self.dbHelper searchWithSQL:queryString toClass:[IMMessage class]];
    if ([array count] == 0) {
        return UNAVALIABLE_MESSAGE_ID;
    }
    IMMessage *message = [array lastObject];
    if (message) {
        return message.msgId;
    }
    return UNAVALIABLE_MESSAGE_ID;
}

- (BOOL)deleteMyContactWithUser:(User*)user
{
    NSString *queryString = [NSString stringWithFormat:@"DELETE FROM CONTACTS WHERE  userId = %hd",user.userId];
   return  [self.dbHelper executeSQL:queryString arguments:nil];
}

@end
