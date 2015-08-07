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

@interface HandlePollingResultOperation()

@property (nonatomic, strong) NSMutableArray *cmdMessages;
@property (nonatomic, strong) NSMutableArray *receiveNewMessages;
@property (nonatomic, strong) NSMutableDictionary *groupMinMessage ;

@end

@implementation HandlePollingResultOperation

- (void)doOperationOnBackground
{
    
    if (self.imService == nil) return;
    User *owner = [IMEnvironment shareInstance].owner;
    
    NSArray *users = self.model.users;
    
    for (NSInteger index = 0; index < [users count]; ++ index)
    {
        User *user = [users objectAtIndex:index];
        
        [self.imService.imStorage insertOrUpdateUser:user];
        
        if (user.userId == owner.userId && user.userRole == owner.userRole)
        {
            owner.name = user.name;
            owner.avatar = user.avatar;
        }
        
        [self.imService updateCacheUser:user];
    }
    
    NSArray *groups = self.model.groups;
    for (NSInteger index = 0; index < [groups count]; ++ index)
    {
        Group *group = [groups objectAtIndex:index];
        
        Group *_group = [self.imService getGroup:group.groupId];
        
        if (_group != nil)
        { //目的是为了更新 cache 中的 Group
            _group.descript = group.descript;
            _group.isPublic = group.isPublic;
            _group.createTime = group.createTime;
            _group.maxusers = group.maxusers;
            _group.status = group.status;
            _group.avatar = group.avatar;
           
            [self.imService.imStorage updateGroup:_group];
        }
        else
        {
            [self.imService.imStorage insertOrUpdateGroup:group];
        }
        
        GroupMember *member = [self.imService.imStorage queryGroupMemberWithGroupId:group.groupId userId:owner.userId userRole:owner.userRole];
        if (member == nil)
        {
            member = [[GroupMember alloc] init];
            member.groupId = group.groupId;
            member.userId = owner.userId;
            member.userRole = owner.userRole;
            [self.imService.imStorage insertGroupMember:member];
        }
    }
    
    NSArray *msgs = self.model.msgs;
    
    for (NSInteger index = 0; index < [msgs count]; ++ index)
    {
        IMMessage *message = [msgs objectAtIndex:index];
        
        if (message.msg_t == eMessageType_CMD)
        {// CMD 消息，不入库
           if (self.cmdMessages == nil)
           {
               self.cmdMessages = [[NSMutableArray alloc] init];
           }
            
            [self.cmdMessages addObject:message];
            continue;
        }
        
        Conversation *conversation = nil;
        if (message.sender == owner.userId && message.senderRole == owner.userRole)
        {
            //如果更换设备登陆，消息链中可能会有之前自己发送的消息
            //判断 message 表中是否已有这条消息，如果没有则入库
            
            IMMessage *_message = [self.imService.imStorage queryMessageWithMessageId:message.msgId];
            if (_message == nil)
            {
                [self.imService.imStorage insertMessage:message];
            }
            else
            {
                message.rowid = _message.rowid;
            }
            
            conversation = [self.imService.imStorage queryConversation:message.sender ownerRole:message.senderRole otherUserOrGroupId:message.receiver userRole:message.receiverRole chatType:message.chat_t];
            
            if (conversation == nil)
            {// 创建新的 conversation，unreadnumber 不增加
                conversation = [[Conversation alloc] init];
                conversation.ownerId = message.sender;
                conversation.ownerRole = message.senderRole;
                conversation.toId = message.receiver;
                conversation.toRole = message.receiverRole;
                conversation.chat_t = message.chat_t;
                conversation.lastMessageId = message.msgId;
                [self.imService.imStorage insertConversation:conversation];
            }
            
            conversation.status = 0;// 会话状态回归正常
            message.status = eMessageStatus_Send_Succ;
            message.read = 1;
            message.played = 1;
            
            message.conversationId = conversation.rowid;
            
            [self.imService.imStorage updateMessage:message];
        }
        else
        { // 接收到的消息
            IMMessage *_message = [self.imService.imStorage queryMessageWithMessageId:message.msgId];
            if(_message != nil)
            {
                // 该消息本地已接受过
                continue;
            }
            
            [self.imService.imStorage insertMessage:message];
        
            if (message.chat_t == eChatType_Chat)
            { // 单聊
                conversation = [self.imService.imStorage queryConversation:message.receiver ownerRole:message.receiverRole otherUserOrGroupId:message.sender userRole:message.senderRole chatType:message.chat_t];
                
                if (conversation == nil)
                {
                    conversation = [[Conversation alloc] init];
                    conversation.ownerId = message.receiver;
                    conversation.ownerRole = message.receiverRole;
                    conversation.toId = message.sender;
                    conversation.toRole = message.senderRole;
                    conversation.chat_t = message.chat_t;
                    conversation.lastMessageId = message.msgId;
                    
                    [self.imService.imStorage insertConversation:conversation];
                }
                
                message.conversationId = conversation.rowid;
                conversation.lastMessageId = message.msgId;
                conversation.unReadNum += 1;
                conversation.status = 0;// 会话状态回归正常
                
                //如果当前正处于这个聊天室， 消息数不增加
                if ([[IMEnvironment shareInstance] isCurrentChatToUser]) {
                    if (conversation.toId == [IMEnvironment shareInstance].currentChatToUserId &&
                        conversation.toRole == [IMEnvironment shareInstance].currentChatToUserRole
                        && conversation.status == 0)
                    {
                        conversation.unReadNum -= 1;
                    }
                }
                
                [self.imService.imStorage updateMessage:message];
                [self.imService.imStorage updateConversation:conversation];
            }
            else
            { // 群聊
                conversation = [self.imService.imStorage queryConversation:owner.userId ownerRole:owner.userRole otherUserOrGroupId:message.receiver userRole:message.receiverRole chatType:message.chat_t];
                
                Group *chatToGroup = [self.imService getGroup:message.receiver];
                if (conversation == nil)
                {
                    conversation = [[Conversation alloc] init];
                    conversation.ownerId = owner.userId;
                    conversation.ownerRole = owner.userRole;
                    conversation.toId = message.receiver;
                    conversation.toRole = message.receiverRole;
                    conversation.chat_t = message.chat_t;
                    conversation.lastMessageId = message.msgId;
                    
                    chatToGroup.startMessageId = message.msgId;
                    chatToGroup.endMessageId = message.msgId;
                    [self.imService.imStorage insertConversation:conversation];
                }
                else
                {
                    IMMessage *_lastMsg = [self.imService.imStorage queryMessageWithMessageId:conversation.lastMessageId];
                    if (_lastMsg.msgId < message.msgId)
                    {
                        conversation.lastMessageId = message.msgId;
                    }
                }
                conversation.status = 0;// 会话状态回归正常
                
                // 处理群消息空洞
                if (message.msgId > chatToGroup.lastMessageId)
                {
                    chatToGroup.lastMessageId = message.msgId;
                }
                
                message.conversationId = conversation.rowid;
                
                [self.imService.imStorage updateMessage:message];
                [self.imService.imStorage updateConversation:conversation];
                [self.imService.imStorage updateGroup:chatToGroup];
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
            
            double endMsgId = [[self.groupMinMessage valueForKey:[NSString stringWithFormat:@"%lld", conversation.toId]] doubleValue];
            if (endMsgId == 0 || endMsgId > message.msgId)
            {
                endMsgId = message.msgId;
            }
            
            [self.groupMinMessage setValue:[NSString stringWithFormat:@"%lf", endMsgId] forKey:[NSString stringWithFormat:@"%lld", conversation.toId]];
        }
    }
    
    NSArray *unread_number = self.model.unread_number;
    for (NSInteger index = 0; index < [unread_number count]; ++ index)
    {
        UnReadNum *num = [unread_number objectAtIndex:index];
        Conversation *conversation = [self.imService.imStorage queryConversation:owner.userId ownerRole:owner.userRole otherUserOrGroupId:num.group_id userRole:eUserRole_Teacher chatType:eChatType_GroupChat];
        
        if (conversation)
        {
            conversation.unReadNum = num.num;
            [self.imService.imStorage updateConversation:conversation];
        }
    }
    
    //处理群组 eid
    [self.groupMinMessage enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        int64_t group_id = [key longLongValue];
        Group *group = [self.imService getGroup:group_id];
        if (group == nil) return ;
        
        group.endMessageId = [obj doubleValue];
        group.lastMessageId = [self.imService.imStorage queryMaxMsgIdGroupChat:group_id];
        
        if (group.endMessageId <= group.startMessageId)
        {
            group.endMessageId = group.lastMessageId;
            group.startMessageId = group.lastMessageId;
        }
        
        [self.imService.imStorage updateGroup:group];
    }];
    
    [self.receiveNewMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IMMessage *__message = (IMMessage *)obj;
        __message.imService = _imService;
    }];

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
}

@end
