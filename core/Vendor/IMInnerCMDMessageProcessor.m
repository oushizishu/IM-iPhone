//
//  IMInnerCMDMessageProcessor.m
//  Pods
//
//  Created by 杨磊 on 15/10/22.
//
//

#import "IMInnerCMDMessageProcessor.h"
#import "BJIMConstants.h"
#import "IMEnvironment.h"

#define ACTION_CMD_INNER_NEW_FANS       @"new_fans"
#define ACTION_CMD_INNER_REMOVE_FANS    @"remove_fans"

@implementation IMInnerCMDMessageProcessor

+ (BOOL)processMessage:(IMMessage *)message withService:(BJIMService *)imService
{
    if (message.msg_t != eMessageType_CMD)
        return NO;
    
    IMCmdMessageBody *messageBody = (IMCmdMessageBody *)message.messageBody;
    if (messageBody.type != 0) return NO; // 非内部处理
    
    NSDictionary *dic = messageBody.payload;
    NSString *action  = dic[@"action"];
    
    if ([action isEqualToString:ACTION_CMD_INNER_NEW_FANS]) {
        // 添加新粉丝
        [IMInnerCMDMessageProcessor dealAddFreshFans:messageBody service:imService];
    } else if ([action isEqualToString:ACTION_CMD_INNER_REMOVE_FANS]) {
        [IMInnerCMDMessageProcessor dealRemoveFreshFans:messageBody service:imService];
    }
    
    

    return YES;
}

+ (void)dealRemoveFreshFans:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [User modelWithDictionary:messageBody.payload[@"user"] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.socialContactsDao deleteFreshFans:user withOwner:owner];
    
    Conversation *freshFansConversation = [imService getConversationUserOrGroupId:user.userId userRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
    
    if (freshFansConversation) {
        freshFansConversation.unReadNum = [imService.imStorage.nFansContactDao queryFreshFansCount:owner];
        [imService.imStorage.conversationDao update:freshFansConversation];
    }
    
    SocialContacts *contact = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (contact) {
        if (contact.focusType == eIMFocusType_Passive) {
            contact.focusType = eIMFocusType_None;
        } else if (contact.focusType == eIMFocusType_Both) {
            contact.focusType = eIMFocusType_Active;
        }
        [imService.imStorage.socialContactsDao update:contact];
    }
}

+ (void)dealAddFreshFans:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [User modelWithDictionary:messageBody.payload[@"user"] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.userDao insertOrUpdateUser:user];
    
    SocialContacts *contact = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (contact == nil) {
        [imService.imStorage.socialContactsDao insert:user withOwner:owner];
    } else {
        if (contact.focusType == eIMFocusType_None) {
            contact.focusType = eIMFocusType_Passive;
        } else if (contact.focusType == eIMFocusType_Active) {
            contact.focusType = eIMFocusType_Both;
        }
        
        [imService.imStorage.socialContactsDao update:contact];
    }
        
    
    
    // 同时创建“新粉丝”会话
    Conversation *freshFansConversation = [imService getConversationUserOrGroupId:user.userId userRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
    
    if (! freshFansConversation) {
        freshFansConversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:USER_FRESH_FANS toRole:eUserRole_Fans lastMessageId:nil chatType:eChatType_Chat];
        [imService.imStorage.conversationDao insert:freshFansConversation];
    }
    
    // 做一条不存在的 msgId。 为了排序
    freshFansConversation.lastMessageId = [NSString stringWithFormat:@"%015.3lf", [[imService.imStorage.conversationDao queryStrangerConversationsMaxMsgId:owner.userId ownerRole:owner.userRole] doubleValue] + 0.001];
    
    freshFansConversation.unReadNum = [imService.imStorage.nFansContactDao queryFreshFansCount:owner];
    [imService.imStorage.conversationDao update:freshFansConversation];

}

@end