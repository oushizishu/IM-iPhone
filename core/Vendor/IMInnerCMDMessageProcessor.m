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
#import "NSString+Json.h"

#define ACTION_CMD_INNER_NEW_FANS       @"new_fans"
#define ACTION_CMD_INNER_REMOVE_FANS    @"remove_fans"
#define ACTION_CMD_CONTACT_INFO_CHANGE  @"contact_info_change"

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
    } else if ([action isEqualToString:ACTION_CMD_CONTACT_INFO_CHANGE]) {
        [IMInnerCMDMessageProcessor dealContactInfoChange:messageBody service:imService];
    }
    
    

    return YES;
}

+ (void)dealRemoveFreshFans:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.socialContactsDao deleteFreshFans:user withOwner:owner];
    [imService.imStorage.nFansContactDao deleteFreshFans:user owner:owner];
    
    Conversation *freshFansConversation = [imService getConversationUserOrGroupId:USER_FRESH_FANS userRole:eUserRole_Fans ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
    
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
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.userDao insertOrUpdateUser:user];
    
    [imService.imStorage.nFansContactDao addFreshFans:user owner:owner];
    
    SocialContacts *contact = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (contact == nil) {
        [imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:owner];
    } else {
        if (contact.focusType == eIMFocusType_None) {
            contact.focusType = eIMFocusType_Passive;
        } else if (contact.focusType == eIMFocusType_Active) {
            contact.focusType = eIMFocusType_Both;
        }
        
        [imService.imStorage.socialContactsDao update:contact];
    }
    
    
    
    // 同时创建“新粉丝”会话
    Conversation *freshFansConversation = [imService getConversationUserOrGroupId:USER_FRESH_FANS userRole:eUserRole_Fans ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
    
    if (! freshFansConversation) {
        freshFansConversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:USER_FRESH_FANS toRole:eUserRole_Fans lastMessageId:nil chatType:eChatType_Chat];
        [imService.imStorage.conversationDao insert:freshFansConversation];
    }
    
    // 做一条不存在的 msgId。 为了排序
    freshFansConversation.lastMessageId = [imService.imStorage nextFakeMessageId];
    freshFansConversation.status = 0; //被删除状态回归正常
    
    freshFansConversation.unReadNum = [imService.imStorage.nFansContactDao queryFreshFansCount:owner];
    [imService.imStorage.conversationDao update:freshFansConversation];

}

+ (void)dealContactInfoChange:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.userDao insertOrUpdateUser:user];
    
    [imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:owner];
    
    SocialContacts *social = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (social == nil) return;
    if (social.blackStatus >= eIMBlackStatus_Active) {
        // 拉黑了对方，将其移除联系人
        [imService.imStorage deleteContactId:user.userId contactRole:user.userRole owner:owner];
    }

}

@end
