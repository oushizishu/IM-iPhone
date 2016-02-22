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

//设置会话relation状态
- (void)setConversationRelation:(Conversation*)conversation withRelation:(CONVERSATION_RELATION)relation;

//删除用户所有会话
- (void)deleteAllConversation:(int64_t)ownerId userRole:(IMUserRole)ownerRole;
//获取所有会话
- (NSArray *)loadAllNoConditionWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole;

/**
 *  返回非陌生人的会话
 *
 *  @param ownerId   <#ownerId description#>
 *  @param ownerRole <#ownerRole description#>
 *
 *  @return <#return value description#>
 */
- (NSArray *)loadAllWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole;

/**
 *  计算所有被隐藏的会话的未读消息总数
  1、群免打扰消息
 *
 *  @param owner <#owner description#>
 *
 *  @return <#return value description#>
 */
- (NSInteger)sumOfAllUnReadNumBeenHiden:(User *)owner;
@end
