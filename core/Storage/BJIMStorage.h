//
//  BJIMStorage.h
//  Pods
//
//  Created by 杨磊 on 15/5/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
@class BJIMConversationDBManager;
@class User;
@class Group;
@class IMMessage;
@class Conversation;
@class GroupMember;
@class RecentContacts;
@interface BJIMStorage : NSObject

//user
- (User*)queryUser:(int64_t)userId userRole:(NSInteger)userRole;
- (void)queryAndSetUserRemark:(User *)user owner:(User *)owner;
- (BOOL)insertOrUpdateUser:(User *)user;

//group
- (Group*)queryGroup:(Group*)group;
- (BOOL)insertOrUpdateGroup:(Group*)group;
- (void)updateGroup:(Group*)group;
- (Group*)queryGroupWithGroupId:(int64_t)groupId;
- (NSArray *)queryGroupsWithUser:(User *)user;

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
- (BOOL)insertOrUpdateContactOwner:(User*)owner contact:(User*)contact;
- (BOOL)deleteMyContactWithUser:(User*)user;
- (BOOL)deleteMyGroups:(User *)user;

- (NSArray*)queryTeacherContactWithUserId:(int64_t)userId userRole:(IMUserRole)userRole;
- (NSArray*)queryStudentContactWithUserId:(int64_t)userId userRole:(IMUserRole)userRole;
- (NSArray*)queryInstitutionContactWithUserId:(int64_t)userId userRole:(IMUserRole)userRole;
- (NSArray *)queryRecentContactsWithUserId:(int64_t)userId userRole:(IMUserRole)userRole;

//groupMember
- (GroupMember*)queryGroupMemberWithGroupId:(int64_t)groupId userId:(int64_t)userId userRole:(IMUserRole)userRole;
- (BOOL)insertGroupMember:(GroupMember*)groupMember;
- (BOOL)insertOrUpdateGroupMember:(GroupMember *)groupMember;
- (BOOL)updateGroupMember:(GroupMember *)groupMember;
- (BOOL)deleteGroup:(int64_t)groupId;
- (BOOL)deleteGroup:(int64_t)groupId user:(User *)user;

//other 
- (BOOL)checkMessageStatus;
-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId minMsgId:(NSString *)minMsgId;

// msgId 长度小于 11
- (NSArray *)queryAllBugMessages;

@end
