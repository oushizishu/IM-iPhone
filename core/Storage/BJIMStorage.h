//
//  BJIMStorage.h
//  Pods
//
//  Created by 杨磊 on 15/5/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "UserDao.h"
#import "InstitutionContactDao.h"
#import "StudentContactDao.h"
#import "TeacherContactDao.h"
#import "GroupDao.h"
#import "GroupMemberDao.h"

@class BJIMConversationDBManager;
@class User;
@class Group;
@class IMMessage;
@class Conversation;
@class GroupMember;
@class RecentContacts;
@interface BJIMStorage : NSObject

@property (nonatomic, strong) UserDao *userDao;
@property (nonatomic, strong) InstitutionContactDao *institutionDao;
@property (nonatomic, strong) StudentContactDao *studentDao;
@property (nonatomic, strong) TeacherContactDao *teacherDao;
@property (nonatomic, strong) GroupDao *groupDao;
@property (nonatomic, strong) GroupMemberDao *groupMemberDao;

//message
- (BOOL)insertMessage:(IMMessage*)message;
- (IMMessage*)queryMessage:(NSInteger)messageRowid;
- (IMMessage*)queryMessageWithMessageId:(NSString *)messageId;
- (BOOL)updateMessage:(IMMessage*)message;
- (NSArray *)loadChatMessagesInConversation:(NSInteger)conversationId;
- (NSArray *)loadGroupChatMessages:(Group *)group inConversation:(NSInteger)conversationId;

- (NSString *)queryChatLastMsgIdOwnerId:(int64_t)ownerId ownerRole:(IMUserRole)ownerRole;
- (NSArray *)queryChatExludeMessagesMaxMsgId:(NSString *)maxMsgId;
- (NSString *)queryGroupChatLastMsgId:(int64_t)groupId withoutSender:(int64_t)sender sendRole:(NSInteger)senderRole;
- (NSString *)queryMaxMsgIdGroupChat:(int64_t)groupId;
- (NSArray *)queryGroupChatExcludeMsgs:(int64_t)groupId maxMsgId:(NSString *)maxMsgId;
// 群组会话最大的消息id 
- (NSString *)queryGroupConversationMaxMsgId:(int64_t)groupId owner:(int64_t)ownerId role:(NSInteger)ownerRole;
// 查询会话的最小 msgId
- (NSString *)queryMinMsgIdInConversation:(NSInteger)conversationId;
// 查询会话最大的 msgId
- (NSString *)queryMaxMsgIdInConversation:(NSInteger)conversationId;
- (NSString *)queryAllMessageMaxMsgId;
// 根据 id 区间查询 messages
- (NSArray *)loadMoreMessagesConversation:(NSInteger)conversationId
                                 minMsgId:(NSString *)minMsgId
                                 maxMsgId:(NSString *)maxMsgId;

//conversation
- (BOOL)insertConversation:(NSObject *)conversation;
- (NSArray*)queryAllConversationOwnerId:(int64_t)ownerId
                               userRole:(IMUserRole)userRole;
- (Conversation*)queryConversation:(int64_t)conversationId;
- (Conversation*)queryConversation:(int64_t)ownerId
                          ownerRole:(IMUserRole)ownerRole
                otherUserOrGroupId:(int64_t)userId
                          userRole:(IMUserRole)otherRserRole
                          chatType:(IMChatType)chatType;

- (void)updateConversation:(Conversation *)conversation;
- (long)sumOfAllConversationUnReadNumOwnerId:(int64_t)ownerId userRole:(IMUserRole)userRole;

//contact
- (BOOL)hasContactOwner:(User*)owner contact:(User*)contact;
- (void)insertOrUpdateContactOwner:(User*)owner contact:(User*)contact;
- (void)deleteMyContactWithUser:(User*)user;

- (NSArray *)queryRecentContactsWithUserId:(int64_t)userId userRole:(IMUserRole)userRole;

//other
- (BOOL)checkMessageStatus;
-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId minMsgId:(NSString *)minMsgId;

// bugfix
// msgId 长度小于 11
- (NSArray *)queryAllBugMessages;
- (void)updateConversationWithErrorLastMessageId:(NSString *)errMsgId newMsgId:(NSString *)msgId;
- (void)updateGroupErrorMsgId:(NSString *)errMsgId newMsgId:(NSString *)msgId;

@end
