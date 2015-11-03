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
 *  查询所有陌生人关系的会话
 *
 *  @param ownerId   <#ownerId description#>
 *  @param ownerRole <#ownerRole description#>
 *
 *  @return <#return value description#>
 */
- (NSArray *)loadAllStrangerWithOwnerId:(int64_t)ownerId userRole:(IMUserRole)ownerRole;

/**
 *  计算 未读消息数>0的陌生人会话的记录条数
 *
 *  @param ownerId   <#ownerId description#>
 *  @param ownerRole <#ownerRole description#>
 *
 *  @return <#return value description#>
 */
- (NSInteger)countOfStrangerCovnersationAndUnreadNumNotZero:(int64_t)ownerId userRole:(IMUserRole)ownerRole;

- (NSString *)queryStrangerConversationsMaxMsgId:(int64_t)ownerId ownerRole:(IMUserRole)ownerRole;

/**
 *  计算所有被隐藏的会话的未读消息总数
  1、群免打扰消息
  2、陌生人会话消息 
  3、新粉丝会话消息
 *
 *  @param owner <#owner description#>
 *
 *  @return <#return value description#>
 */
- (NSInteger)sumOfAllUnReadNumBeenHiden:(User *)owner;
@end
