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
@interface BJIMStorage : NSObject

//user
- (User*)queryUser:(int64_t)userId userRole:(int)userRole;
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
- (IMMessage*)queryMessageWithMessageId:(int64_t)messageId;
- (BOOL)updateMessage:(IMMessage*)message;
- (NSArray *)loadChatMessagesInConversation:(int64_t)conversationId;
- (NSArray *)loadGroupChatMessages:(Group *)group inConversation:(int64_t)conversationId;

- (double)queryChatLastMsgIdOwnerId:(int64_t)ownerId  ownerRole:(IMUserRole)ownerRole;
- (double)queryGroupChatLastMsgId:(int64_t)groupId withoutSender:(int64_t)sender sendRole:(NSInteger)senderRole;
// 群组会话最大的消息id 
- (double)queryGroupConversationMaxMsgId:(int64_t)groupId owner:(int64_t)ownerId role:(NSInteger)ownerRole;
// 查询会话的最小 msgId
- (double)queryMinMsgIdInConversation:(int64_t)conversationId;
// 根据 id 区间查询 messages
- (NSArray *)loadMoreMessagesConversation:(NSInteger)conversationId
                                 minMsgId:(double_t)minMsgId
                                 maxMsgId:(double_t)maxMsgId;

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


- (NSArray*)queryTeacherContactWithUserId:(long)userId userRole:(IMUserRole)userRole;;
- (NSArray*)queryStudentContactWithUserId:(long)userId userRole:(IMUserRole)userRole;
- (NSArray*)queryInstitutionContactWithUserId:(long)userId userRole:(IMUserRole)userRole;

//groupMember
- (GroupMember*)queryGroupMemberWithGroupId:(long)groupId userId:(long)userId userRole:(IMUserRole)userRole;
- (BOOL)insertGroupMember:(GroupMember*)groupMember;

//other 
- ( BOOL)checkMessageStatus;
-  (NSArray*)loadMoreMessageWithConversationId:(NSInteger)conversationId minMsgId:(double)minMsgId;


- (double)getConversationMaxMsgId:(int64_t)conversationId;

@end
