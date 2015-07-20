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
@interface BJIMStorage : NSObject

//user
- (User*)queryUser:(int64_t)userId userRole:(int)userRole;
- (BOOL)insertOrUpdateUser:(User *)user;

//group
- (Group*)queryGroup:(Group*)group;
- (BOOL)insertOrUpdateGroup:(Group*)group;
- (void)updateGroup:(Group*)group;
- (Group*)queryGroupWithGroupId:(long)groupId;

//message
- (BOOL)insertMessage:(IMMessage*)message;
- (IMMessage*)queryMessage:(int64_t)messageId;
- (IMMessage*)queryMessageWithMessageId:(int64_t)messageId;
- (BOOL)updateMessage:(IMMessage*)message;
- (NSArray *)loadChatMessagesInConversation:(int64_t)conversationId;
- (NSArray *)loadGroupChatMessages:(Group *)group inConversation:(int64_t)conversationId;

- (double)queryChatLastMsgIdOwnerId:(long)ownerId  ownerRole:(IMUserRole)ownerRole;
- (double)queryGroupChatLastMsgId:(long)groupId;

//conversation
- (BOOL)insertConversation:(NSObject *)conversation;
- (NSArray*)queryAllConversationOwnerId:(long)ownerId
                               userRole:(IMUserRole)userRole;
- (Conversation*)queryConversation:(long)conversationId;
- (Conversation*)queryConversation:(long)ownerId
                          userRole:(IMUserRole)userRole
                otherUserOrGroupId:(long)userId
                          userRole:(IMUserRole)otherRserRole
                          chatType:(IMChatType)chatType;

- (long)sumOfAllConversationUnReadNumOwnerId:(long)ownerId userRole:(IMUserRole)userRole;

//contact
- (BOOL)hasContactOwner:(User*)owner contact:(User*)contact;
- (BOOL)insertOrUpdateContactOwner:(User*)owner contact:(User*)contact;
- (BOOL)deleteMyContactWithUser:(User*)user;

- (NSArray*)queryTeacherContactWithUserId:(long)userId userRole:(IMUserRole)userRole;;
- (NSArray*)queryStudentContactWithUserId:(long)userId userRole:(IMUserRole)userRole;
- (NSArray*)queryInstitutionContactWithUserId:(long)userId userRole:(IMUserRole)userRole;

//other
- ( BOOL)checkMessageStatus;
-  (NSArray*)loadMoreMessageWithConversationId:(long)conversationId minMsgId:(double)minMsgId;
- (void)queryGroupMemberWithGroupId:(long)groupId userId:(long)userId userRole:(IMUserRole)userRole;
- (BOOL)insertGroupMember:(Group*)groupMember;
- (double)getConversationMaxMsgId:(long)conversationId;

@end
