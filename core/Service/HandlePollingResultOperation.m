
//
//  HandlePollingResultOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "HandlePollingResultOperation.h"
#import "BJIMService.h"
#import "PollingResultModel.h"
#import "IMMessage.h"
#import "User.h"
#import "Group.h"
#import "GroupMember.h"
#import "IMMessage+DB.h"

#import "IMEnvironment.h"
#import "HandleGetMsgOperation.h"
#import "IMInnerCMDMessageProcessor.h"

@interface HandlePollingResultOperation()

@property (nonatomic, strong) NSMutableArray *cmdMessages;
@property (nonatomic, strong) NSMutableArray *receiveNewMessages;
@property (nonatomic, strong) NSMutableDictionary *groupMinMessage ;

@property (nonatomic, assign) NSInteger allUnReadNum;
@property (nonatomic, assign) NSInteger otherUnReadNum;

@end

@implementation HandlePollingResultOperation

- (void)updateUsers:(User *)owner users:(NSArray *)users
{
    for (NSInteger index = 0; index < [users count]; ++ index)
    {
        User *user = [users objectAtIndex:index];
        
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        
        if (user.userId == owner.userId && user.userRole == owner.userRole)
        {
            owner.name = user.name;
            owner.avatar = user.avatar;
        }
        if (user.userRole == eUserRole_Teacher || user.userRole == eUserRole_Student || user.userRole == eUserRole_Institution) {
            SocialContacts *contacts = [self.imService.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
            if (contacts != nil) {
                contacts.remarkName = user.remarkName;
                contacts.remarkHeader = user.remarkHeader;
                contacts.blackStatus = user.blackStatus;
                contacts.originType = user.originType;
                contacts.focusType = user.focusType;
                contacts.tinyFoucs = user.tinyFocus;
                if (user.focusTime != nil) {
                    contacts.focusTime = user.focusTime;
                }
                if (user.fansTime != nil) {
                    contacts.fansTime = user.fansTime;
                }
                
                [self.imService.imStorage.socialContactsDao update:contacts];
            }else
            {
                [self.imService.imStorage.socialContactsDao insert:user withOwner:owner];
            }
        }
    }
}

- (void)updateGroups:(User *)owner groups:(NSArray *)groups
{
    for (NSInteger index = 0; index < [groups count]; ++ index)
    {
        Group *group = [groups objectAtIndex:index];
        
        Group *oldgGroup = [self.imService.imStorage.groupDao load:group.groupId];
        oldgGroup.groupName = group.groupName;
        oldgGroup.avatar = group.avatar;
        oldgGroup.descript = group.descript;
        oldgGroup.isPublic = group.isPublic;
        oldgGroup.maxusers = group.maxusers;
        oldgGroup.approval = group.approval;
        oldgGroup.memberCount = group.memberCount;
        oldgGroup.status = group.status;
        
        [self.imService.imStorage.groupDao insertOrUpdate:oldgGroup];
        
        GroupMember *member = [self.imService.imStorage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:group.groupId];
        if (member == nil)
        {
            member = [[GroupMember alloc] init];
            member.groupId = group.groupId;
            member.userId = owner.userId;
            member.userRole = owner.userRole;
            [self.imService.imStorage.groupMemberDao insertOrUpdate:member];
        }
    }
}

- (Conversation *)dealSendedMessage:(IMMessage *)message
{
    Conversation *conversation = nil;
    if (message.chat_t == eChatType_Chat) {
        if (! [self checkHasUser:message.receiver role:message.receiverRole array:self.model.users])
        {
            //垃圾消息
            return nil;
        }
    }
    else
    {
        if (! [self checkhasGroup:message.receiver array:self.model.groups])
        {
            // 垃圾消息
            return nil;
        }
    }
    
    //如果更换设备登陆，消息链中可能会有之前自己发送的消息
    //判断 message 表中是否已有这条消息，如果没有则入库
    IMMessage *_message = [self.imService.imStorage.messageDao loadWithMessageId:message.msgId];
    if (_message == nil)
    {
        [self.imService.imStorage.messageDao insert:message];
    }
    
    conversation = [self.imService getConversationUserOrGroupId:message.receiver userRole:message.receiverRole ownerId:message.sender ownerRole:message.senderRole chat_t:message.chat_t];
    
    if (conversation == nil)
    {// 创建新的 conversation，unreadnumber 不增加
        conversation = [[Conversation alloc] initWithOwnerId:message.sender ownerRole:message.senderRole toId:message.receiver toRole:message.receiverRole lastMessageId:message.msgId chatType:message.chat_t];
        
        User *owner = [IMEnvironment shareInstance].owner;
        
        if(message.chat_t == eChatType_Chat)
        {
            User *user = [self.imService getUser:message.receiver role:message.receiverRole];
            //判断会话对象是否为陌生人
            if ([self.imService getIsStanger:user withUser:owner]) {
                conversation.relation = 1;
                
                //获取陌生人会话
                Conversation *stangerConversation = [self.imService getConversationUserOrGroupId:-1000100 userRole:-2 ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_Chat];
                if (stangerConversation == nil) {
                    stangerConversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:-1000100 toRole:-2 lastMessageId:message.msgId chatType:eChatType_Chat];
                    [self.imService.imStorage.conversationDao insert:stangerConversation];
                }else
                {
                    stangerConversation.lastMessageId = message.msgId;
                    [self.imService.imStorage.conversationDao update:stangerConversation];
                }
            }
        }
        
        [self.imService insertConversation:conversation];
    }
    else
    {
        if ([_message.msgId doubleValue] > [conversation.lastMessageId doubleValue]) {
            conversation.lastMessageId = _message.msgId;
            [self.imService.imStorage.conversationDao update:conversation];
        }
    }
    
    //conversation.status = 0;// 会话状态回归正常
    message.status = eMessageStatus_Send_Succ;
    message.read = 1;
    message.played = 1;
    
    message.conversationId = conversation.rowid;
    
    [self.imService.imStorage.messageDao update:message];
    return conversation;
}

- (Conversation *)dealReceiveChatMessage:(IMMessage *)message
{
    Conversation *conversation = nil;
    conversation = [self.imService getConversationUserOrGroupId:message.sender userRole:message.senderRole ownerId:message.receiver ownerRole:message.receiverRole chat_t:message.chat_t];
    
    if (conversation == nil)
    {
        conversation = [[Conversation alloc] initWithOwnerId:message.receiver ownerRole:message.receiverRole toId:message.sender toRole:message.senderRole lastMessageId:message.msgId chatType:message.chat_t];
        
        [self.imService insertConversation:conversation];
    }
    else
    {
        if ([conversation.lastMessageId doubleValue] < [message.msgId doubleValue])
        {
            conversation.lastMessageId = message.msgId;
        }
    }
    
    message.conversationId = conversation.rowid;
    //                conversation.lastMessageId = message.msgId;
    if (message.msg_t != eMessageType_NOTIFICATION) {
        // 通知消息未读数不增加
        conversation.unReadNum += 1;
    }
    
    if (! [self isKindOfClass:[HandleGetMsgOperation class]]) {
        conversation.status = 0;// 会话状态回归正常
    }
    
    User *owner = [IMEnvironment shareInstance].owner;
    User *toUser = [self.imService.imStorage.userDao loadUser:message.sender role:message.senderRole];
    
    if ([self.imService getIsStanger:owner withUser:toUser] && conversation.chat_t == eChatType_Chat && conversation.relation != eConversation_Relation_Stranger) {
        conversation.relation = eConversation_Relation_Stranger;
    }
    
    //如果当前正处于这个聊天室， 消息数不增加
    if ([[IMEnvironment shareInstance] isCurrentChatToUser]) {
        if (conversation.toId == [IMEnvironment shareInstance].currentChatToUserId &&
            conversation.toRole == [IMEnvironment shareInstance].currentChatToUserRole &&
            conversation.status == 0)
        {
            if (message.msg_t != eMessageType_NOTIFICATION) {
                conversation.unReadNum -= 1;
            }
        }
    }
    
    [self.imService.imStorage.messageDao update:message];
    [self.imService.imStorage.conversationDao update:conversation];
    
    //判断会话对象是否为陌生人, 处理“陌生人消息”会话的maxMsgId, unReadNum
    if ([self.imService getIsStanger:owner withUser:toUser] && ! [self isKindOfClass:[HandleGetMsgOperation class]]) {
        
        //获取陌生人会话
        Conversation *strangerConversation = [self.imService getConversationUserOrGroupId:USER_STRANGER userRole:eUserRole_Stanger ownerId:message.receiver ownerRole:message.receiverRole chat_t:eChatType_Chat];
        
        if (strangerConversation == nil) {
            strangerConversation = [[Conversation alloc] initWithOwnerId:message.receiver ownerRole:message.receiverRole toId:USER_STRANGER toRole:eUserRole_Stanger lastMessageId:message.msgId chatType:eChatType_Chat];
            
            [self.imService.imStorage.conversationDao insert:strangerConversation];
        }
        
        strangerConversation.lastMessageId = [self.imService.imStorage.conversationDao queryStrangerConversationsMaxMsgId:message.receiver ownerRole:message.receiverRole];
        NSInteger count =[self.imService.imStorage.conversationDao countOfStrangerCovnersationAndUnreadNumNotZero:owner.userId userRole:owner.userRole];
        if (count != strangerConversation.unReadNum) {
            strangerConversation.status = 0;
        }

        strangerConversation.unReadNum = count;
        
        [self.imService.imStorage.conversationDao update:strangerConversation];
        
    }
    
    return conversation;
}

- (Conversation *)dealReceiveGroupChatMessage:(IMMessage *)message owner:(User *)owner
{
    Conversation *conversation = nil;
    conversation = [self.imService getConversationUserOrGroupId:message.receiver userRole:message.receiverRole ownerId:owner.userId ownerRole:owner.userRole chat_t:message.chat_t];
    
    Group *chatToGroup = [self.imService.imStorage.groupDao load:message.receiver];
    if (conversation == nil)
    {
        conversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:message.receiver toRole:message.receiverRole lastMessageId:message.msgId chatType:message.chat_t];
        
        chatToGroup.startMessageId = message.msgId;
        chatToGroup.endMessageId = message.msgId;
        [self.imService insertConversation:conversation];
    }
    else
    {
        //  IMMessage *_lastMsg = [self.imService.imStorage queryMessageWithMessageId:conversation.lastMessageId];
        if ([conversation.lastMessageId doubleValue] < [message.msgId doubleValue])
        {
            conversation.lastMessageId = message.msgId;
        }
    }
    
    if (! [self isKindOfClass:[HandleGetMsgOperation class]]) {
        conversation.status = 0;// 会话状态回归正常
    }
    
    // 处理群消息空洞
    if ([message.msgId doubleValue]> [chatToGroup.lastMessageId doubleValue])
    {
        chatToGroup.lastMessageId = message.msgId;
    }
    
    message.conversationId = conversation.rowid;
    
    //设置会话关系，根据群是否开启面打扰
    if (chatToGroup.pushStatus == eGroupPushStatus_open) {
        conversation.relation = eConversation_Relation_Group_Closed;
    } else {
        conversation.relation = eConverastion_Relation_Normal;
    }
    
    [self.imService.imStorage.messageDao update:message];
    [self.imService.imStorage.conversationDao update:conversation];
    [self.imService.imStorage.groupDao insertOrUpdate:chatToGroup];
    return conversation;
}

- (void)doOperationOnBackground
{
    
    if (self.imService == nil) return;
    User *owner = [IMEnvironment shareInstance].owner;
    
    NSArray *users = self.model.users;
    [self updateUsers:owner users:users];
    
    NSArray *groups = self.model.groups;
    [self updateGroups:owner groups:groups];
    
    NSArray *msgs = self.model.msgs;
    
    for (NSInteger index = 0; index < [msgs count]; ++ index)
    {
        IMMessage *message = [msgs objectAtIndex:index];
        
        if (message.msg_t == eMessageType_CMD)
        {// CMD 消息，不入库
            //记录收到的最大cmd消息
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            NSString *cmdMsgKey = [NSString stringWithFormat:@"%lld_%ld_CMDMessage_MAXID",owner.userId, (long)owner.userRole];
            NSString *oldCmdMsgId = [user objectForKey:cmdMsgKey];
            if ([oldCmdMsgId longLongValue] < [message.msgId longLongValue]) {
                [user setObject:message.msgId forKey: cmdMsgKey];
                [user synchronize];
            }
            
           if (self.cmdMessages == nil)
           {
               self.cmdMessages = [[NSMutableArray alloc] init];
           }
            
            BOOL suc = [IMInnerCMDMessageProcessor processMessage:message withService:self.imService];
            
            if (! suc) {
                [self.cmdMessages addObject:message];
            }
            continue;
        }
        
        Conversation *conversation = nil;
        if (message.sender == owner.userId && message.senderRole == owner.userRole)
        {
            
            conversation = [self dealSendedMessage:message];
        }
        else
        { // 接收到的消息
            IMMessage *_message = [self.imService.imStorage.messageDao loadWithMessageId:message.msgId];
            if(_message != nil)
            {
                // 该消息本地已接受过
                continue;
            }
            
            if (message.chat_t == eChatType_Chat)
            {
                if (! [self checkHasUser:message.sender role:message.senderRole array:self.model.users])
                {
                    // 垃圾消息
                    continue;
                }
            }
            else
            {
                if (![self checkhasGroup:message.receiver array:self.model.groups])
                {
                    //垃圾消息
                    continue;
                }
            }
            
            [self.imService.imStorage.messageDao insert:message];
        
            if (message.chat_t == eChatType_Chat)
            { // 单聊
                conversation = [self dealReceiveChatMessage:message];
            }
            else
            { // 群聊
                conversation = [self dealReceiveGroupChatMessage:message owner:owner];
            }
            
            if (self.receiveNewMessages == nil)
            {
                self.receiveNewMessages = [[NSMutableArray alloc] init];
            }
           
            [self.receiveNewMessages addObject:message];
        }
        
        if (message.chat_t == eChatType_GroupChat)
        {
            if (self.groupMinMessage == nil)
            {
                self.groupMinMessage = [[NSMutableDictionary alloc] init];
            }
            
            NSString *endMsgId = [self.groupMinMessage valueForKey:[NSString stringWithFormat:@"%lld", conversation.toId]];
            if (endMsgId == nil || [endMsgId longLongValue]> [message.msgId longLongValue])
            {
                endMsgId = message.msgId;
            }
            
            [self.groupMinMessage setValue:endMsgId forKey:[NSString stringWithFormat:@"%lld", conversation.toId]];
        }
    }
    
    NSArray *unread_number = self.model.unread_number;
    for (NSInteger index = 0; index < [unread_number count]; ++ index)
    {
        UnReadNum *num = [unread_number objectAtIndex:index];
        Conversation *conversation = [self.imService getConversationUserOrGroupId:num.group_id userRole:eUserRole_Anonymous ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_GroupChat];
        
        if (conversation)
        {
            conversation.unReadNum = num.num;
            [self.imService.imStorage.conversationDao update:conversation];
        }
    }
    
    //处理群组 eid
    [self.groupMinMessage enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        int64_t group_id = [key longLongValue];
        Group *group = [self.imService.imStorage.groupDao load:group_id];
        if (group == nil) return ;
        
        group.endMessageId = value;
        group.lastMessageId = [self.imService.imStorage.messageDao queryMaxMsgIdGroupChat:group_id];
        
        if ([group.endMessageId longLongValue] <= [group.startMessageId longLongValue])
        {
            group.endMessageId = group.lastMessageId;
            group.startMessageId = group.lastMessageId;
        }
        
        [self.imService.imStorage.groupDao insertOrUpdate:group];
    }];
    
    [self.receiveNewMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IMMessage *__message = (IMMessage *)obj;
        __message.imService = _imService;
    }];

    self.allUnReadNum = [self.imService.imStorage sumOfAllConversationUnReadNumOwnerId:owner.userId userRole:owner.userRole];
    self.otherUnReadNum = [self.imService.imStorage.conversationDao sumOfAllUnReadNumBeenHiden:owner];
}

- (void)doAfterOperationOnMain
{
    if (self.receiveNewMessages)
    {
        [self.imService notifyConversationChanged];
        [self.imService notifyReceiveNewMessages:self.receiveNewMessages];
    }
    
    if (self.cmdMessages)
    {
        [self.imService notifyCmdMessages:self.cmdMessages];
    }
    
    [self.imService notifyUnReadNumChanged:self.allUnReadNum other:self.otherUnReadNum];
}

- (BOOL)checkHasUser:(int64_t)userId role:(IMUserRole)role array:(NSArray *)array
{
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        User *user = [array objectAtIndex:index];
        if (user.userId == userId && user.userRole == role)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)checkhasGroup:(int64_t)groupId array:(NSArray *)array
{
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        Group *group = [array objectAtIndex:index];
        if (groupId == group.groupId)
            return YES;
    }
    return NO;
}

@end
