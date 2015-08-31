//
//  ConversationDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "IMBaseDao.h"

#import "Conversation.h"

@interface ConversationDao : IMBaseDao

- (Conversation *)loadWithConversationId:(NSInteger)conversationId;
- (Conversation*)loadWithOwnerId:(int64_t)ownerId
                         ownerRole:(IMUserRole)ownerRole
                otherUserOrGroupId:(int64_t)userId
                          userRole:(IMUserRole)otherRserRole
                          chatType:(IMChatType)chatType;

- (void)insert:(Conversation *)conversation;

- (void)update:(Conversation *)conversation;

- (NSArray *)loadAllWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole;
@end
