//
//  HandleCmdMessageOperation.m
//  Pods
//
//  Created by 杨磊 on 15/11/3.
//
//

#import "HandleCmdMessageOperation.h"
#import "IMEnvironment.h"
#import "NSString+Json.h"
#import "NSDictionary+Json.h"

#define ACTION_CMD_INNER_NEW_FANS       @"new_fans"
#define ACTION_CMD_INNER_REMOVE_FANS    @"remove_fans"
#define ACTION_CMD_CONTACT_INFO_CHANGE  @"contact_info_change"
#define ACTION_CMD_NEW_GROUP_NOTICE     @"new_group_notice"
#define ACTION_CMD_UPDATE_CONTACT       @"update_contact"

@interface HandleCmdMessageOperation()

@property (nonatomic) SEL resultSelector;
@end

@implementation HandleCmdMessageOperation


- (void)doOperationOnBackground
{
   IMCmdMessageBody *messageBody = (IMCmdMessageBody *)self.message.messageBody;
    NSDictionary *dic = messageBody.payload;
    NSString *action  = dic[@"action"];
    
    if ([action isEqualToString:ACTION_CMD_INNER_NEW_FANS]) {
        // 添加新粉丝
        self.resultSelector = [self dealAddFreshFans:messageBody service:self.imService];
    } else if ([action isEqualToString:ACTION_CMD_INNER_REMOVE_FANS]) {
        self.resultSelector =  [self dealRemoveFreshFans:messageBody service:self.imService];
    } else if ([action isEqualToString:ACTION_CMD_CONTACT_INFO_CHANGE]) {
        self.resultSelector = [self dealContactInfoChange:messageBody service:self.imService];
    }else if ([action isEqualToString:ACTION_CMD_NEW_GROUP_NOTICE]) {
        self.resultSelector = [self dealNewGRoupNotice:messageBody service:self.imService];
    }else if ([action isEqualToString:ACTION_CMD_UPDATE_CONTACT])
    {
        self.resultSelector = [self dealUpdateContact:messageBody service:self.imService];
    }
    
}

- (void)doAfterOperationOnMain
{
    if (self.resultSelector && [self.imService respondsToSelector:self.resultSelector]) {
        [self.imService performSelector:self.resultSelector];
    }
}


- (SEL)dealRemoveFreshFans:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.nFansContactDao deleteFreshFans:user owner:owner];
    
    Conversation *freshFansConversation = [imService getConversationUserOrGroupId:USER_FRESH_FANS userRole:eUserRole_Fans ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
    
    SocialContacts *contact = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (contact) {
        if (contact.focusType == eIMFocusType_Passive) {
            contact.focusType = eIMFocusType_None;
        } else if (contact.focusType == eIMFocusType_Both) {
            contact.focusType = eIMFocusType_Active;
        }
        [imService.imStorage.socialContactsDao update:contact];
    }
    
    if (freshFansConversation) {
        freshFansConversation.unReadNum = [imService.imStorage.nFansContactDao queryFreshFansCount:owner];
        [imService.imStorage.conversationDao update:freshFansConversation];
        
        if (freshFansConversation.status == 0) {
            // 新粉丝会话正常显示, 需通知界面刷新
            return @selector(notifyConversationChanged);
        }
    }
    return nil;
}

- (SEL)dealAddFreshFans:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.userDao insertOrUpdateUser:user];
    
    [imService.imStorage.nFansContactDao addFreshFans:user owner:owner];
    [imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:owner];
    
    SocialContacts *contact = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (contact == nil) {
        //        [imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:owner];
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
    
    return @selector(notifyConversationChanged);
}

- (SEL)dealContactInfoChange:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.userDao insertOrUpdateUser:user];
    
    [imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:owner];
    
    SocialContacts *social = [imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    
    if (social == nil) return nil;
    if (social.blackStatus >= eIMBlackStatus_Active) {
        // 拉黑了对方，将其移除联系人
        [imService.imStorage deleteContactId:user.userId contactRole:user.userRole owner:owner];
        return @selector(notifyContactChanged);
    } else if ((social.blackStatus == eIMBlackStatus_Normal || social.blackStatus == eIMBlackStatus_Passive) && social.originType == eIMOriginType_Order) {
        [imService.imStorage insertOrUpdateContactOwner:owner contact:user];
        
        return @selector(notifyContactChanged);
    }
    return nil;
    
}

- (SEL)dealNewGRoupNotice:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSMutableDictionary *notice = [[NSMutableDictionary alloc] initWithDictionary:[messageBody.payload[@"notice"] jsonValue]];
    
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    
    User *owner = [IMEnvironment shareInstance].owner;
    int64_t groupId = [[notice objectForKey:@"group_id"] longLongValue];
    NSString *objectkey = [NSString stringWithFormat:@"UserId_%lld_userRole_%ld_NewGroupNotice_%lld",owner.userId,owner.userRole,groupId];
    
    BOOL ifNotify = YES;
    
    if ([notice objectForKey:@"content"] != nil && [[notice objectForKey:@"content"] length] > 0) {
        NSDictionary *oldNotice = [[userDefaultes objectForKey:objectkey] jsonValue];
        if (oldNotice != nil) {
            if ([[oldNotice objectForKey:@"id"] longLongValue]>=[[notice objectForKey:@"id"] longLongValue]) {
                ifNotify = NO;
                [notice setObject:@"NO" forKey:@"ifAutoShow"];
            }else
            {
                [notice setObject:@"YES" forKey:@"ifAutoShow"];
            }
        }else
        {
            [notice setObject:@"YES" forKey:@"ifAutoShow"];
        }
        
        [userDefaultes setObject:[notice jsonString] forKey:objectkey];
    }else
    {
        ifNotify = NO;
        [userDefaultes removeObjectForKey:objectkey];
    }
    
    [userDefaultes synchronize];
    
    if(ifNotify)
    {
        return @selector(notifyNewGroupNotice);
    }else
    {
        return nil;
    }

    
}

- (SEL)dealUpdateContact:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    [imService.imEngine syncContacts];
    return nil;
}


@end
