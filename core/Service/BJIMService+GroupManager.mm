//
//  BJIMService+GroupManager.m
//  Pods
//
//  Created by Randy on 15/8/6.
//
//

#import "BJIMService+GroupManager.h"
#import "NSError+BJIM.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>
#import "NetWorkTool.h"
#import "BJIMConstants.h"
#import "GroupMemberListData.h"
#import "GroupMember.h"
#import "GetGroupMemberModel.h"
#import "HandleGetGroupMemberOperation.h"

#import "HandleDisbandGroupOperation.h"

static DDLogLevel ddLogLevel = DDLogLevelVerbose;

static char BJGroupMamagerDelegateKey;

@interface BJIMService ()
@property (nonatomic, strong) NSHashTable *groupManagerDelegates;
@end

@implementation BJIMService (GroupManager)

- (void)addGroupManagerDelegate:(id<IMGroupManagerResultDelegate>)delegate;
{
    [self.groupManagerDelegates addObject:delegate];
}

- (void)getGroupProfile:(int64_t)groupId;
{
    //1.检测登录 ok
    //2.检查group是否在本地存在 ok
    //3.更新群关系到本地 ok
    //4.更新group信息到内存、本地 并通知notifyGroupProfileChanged有更新
    //3.回调

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyGetGroupProfile:groupId group:nil error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    User *owner = [IMEnvironment shareInstance].owner;
    [self.imEngine postGetGroupProfile:groupId callback:^(Group *result) {
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyGetGroupProfile:groupId group:nil error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (! result)
        {
            [weakSelf notifyGetGroupProfile:groupId group:nil error:[NSError bjim_errorWithReason:@"请求失败"]];
            return;
        }
        [group mergeValuesForKeysFromModel:result];
        
        
        GroupMember *_groupMember = [weakSelf.imStorage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:group.groupId];
        
        if(_groupMember != nil)
        {
            _groupMember.msgStatus = group.msgStatus;
            _groupMember.canDisband = group.canDisband;
            _groupMember.canLeave = group.canLeave;
            _groupMember.remarkHeader = group.remarkHeader;
            _groupMember.remarkName = group.remarkName;
            _groupMember.pushStatus = group.pushStatus;
            
            [weakSelf.imStorage.groupMemberDao insertOrUpdate:_groupMember];
        }
        
        [weakSelf.imStorage.groupDao insertOrUpdate:group];
        [weakSelf notifyGroupProfileChanged:group];
        [weakSelf notifyGetGroupProfile:groupId group:group error:nil];
    }];
}

- (void)leaveGroupWithGroupId:(int64_t)groupId;
{
    //0.检查登录状态
    //0.检查是否能离开 状态同步不实时，暂不检查 群是否存在
    //1.通知服务器
    //2.服务器成功后本地会话删除 通知上层会话更新。 deleteConversation
    //3.删除group和我的关系 删除内存中我的联系人 通知上层联系人列表更新。
    //4.通知退出成功
    
    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyLeaveGroup:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postLeaveGroup:groupId callback:^(NSError *err) {
        //请求成功
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyLeaveGroup:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (!err) {
            User *owner = [IMEnvironment shareInstance].owner;
            Conversation *conv = [weakSelf getConversationUserOrGroupId:groupId userRole:eUserRole_Anonymous ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_GroupChat];
            if (conv && [weakSelf deleteConversation:conv owner:[IMEnvironment shareInstance].owner]) {
                [weakSelf notifyConversationChanged];
            }
            else
                DDLogError(@"Group Manager fail 删除会话失败");
            
//            if (![weakSelf.imStorage deleteGroup:groupId user:[IMEnvironment shareInstance].owner]) {
//                DDLogError(@"Group Manager fail 删除群和我的关系失败");
//            }
            [weakSelf.imStorage.groupMemberDao deleteGroupMember:groupId user:[IMEnvironment shareInstance].owner];
            [weakSelf notifyContactChanged];
        }
        
        [weakSelf notifyLeaveGroup:groupId error:err];
    }];
}

- (void)disbandGroupWithGroupId:(int64_t)groupId;
{
    //0.检查登录状态
    //0.检查是否能解散 群是否存在
    //1.通知服务器
    //2.服务器成功后本地会话删除 通知上层会话更新。 deleteConversation
    //3.服务器成功后删除group所有成员关系、删除消息，并且删除group 通知上层联系人列表更新。 调用
    //5.通知解散成功

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyDisbandGroup:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postDisBandGroup:groupId callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyDisbandGroup:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        //请求成功
        if (!err) {
            HandleDisbandGroupOperation *operation = [[HandleDisbandGroupOperation alloc] init];
            operation.imService = self;
            operation.groupId = groupId;
            [self.writeOperationQueue addOperation:operation];
            
            /*
            User *owner = [IMEnvironment shareInstance].owner;
            Conversation *conv = [weakSelf getConversationUserOrGroupId:groupId userRole:eUserRole_Anonymous ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_GroupChat];
            if ([weakSelf deleteConversation:conv owner:[IMEnvironment shareInstance].owner]) {
                [weakSelf notifyConversationChanged];
            }
            
            if ([weakSelf.imStorage deleteGroup:groupId] == NO) {
                DDLogError(@"Group Manager fail 删除群所有关系失败");
            }
            [weakSelf notifyContactChanged];
             */
        }
        else
        {
            [weakSelf notifyDisbandGroup:groupId error:err];
        }
    }];
}

- (void)getGroupMemberWithModel:(GetGroupMemberModel *)model
{
    //1.检测登录
    //2.检查group是否在本地存在 检查page的正确
    //3.更细群关系到本地
    //4.更新用户列表信息到本地 保证内存中只有一份user
    //3.回调
    
    if (model.page<1) {
        [self notifyGetGroupMembers:nil model:model error:[NSError bjim_errorWithReason:@"page不能小于1" code:eError_paramsError]];
        return;
    }
    
    Group *group = [self getGroup:model.groupId];
    if (group == nil) {
        [self notifyGetGroupMembers:nil model:model error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postGetGroupMembersWithModel:model callback:^(GroupMemberListData *members, NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [self notifyGetGroupMembers:nil model:model error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (err) {
            [weakSelf notifyGetGroupMembers:nil model:model error:err];
        }
        else
        {
            HandleGetGroupMemberOperation *operation = [[HandleGetGroupMemberOperation alloc] initWithService:self listData:members];
            operation.model = model;
            [self.writeOperationQueue addOperation:operation];
        }
    }];
}

- (void)getGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)page;
{
    //1.检测登录
    //2.检查group是否在本地存在 检查page的正确
    //3.更细群关系到本地
    //4.更新用户列表信息到本地 保证内存中只有一份user
    //3.回调
    
    if (page<1) {
        [self notifyGetGroupMembers:nil userRole:userRole page:page groupId:groupId error:[NSError bjim_errorWithReason:@"page不能小于1" code:eError_paramsError]];
        return;
    }
    
    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyGetGroupMembers:nil userRole:userRole page:page groupId:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postGetGroupMembers:groupId userRole:userRole page:page callback:^(GroupMemberListData *members, NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [self notifyGetGroupMembers:nil userRole:userRole page:page groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (err) {
            [weakSelf notifyGetGroupMembers:nil userRole:userRole page:page groupId:groupId error:err];
        }
        else
        {
            HandleGetGroupMemberOperation *operation = [[HandleGetGroupMemberOperation alloc] initWithService:self listData:members];
            [self.writeOperationQueue addOperation:operation];
        }
        
    }];
}

- (void)changeGroupName:(NSString *)name groupId:(int64_t)groupId;
{
    //1.检测登录
    //2.检查group是否在本地存在
    //3.更新name到本地、内存
    //4.更新group信息到本地 并通知notifyGroupProfileChanged有更新
    //3.回调

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyChangeGroupName:name groupId:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postChangeGroupName:groupId newName:name callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [self notifyChangeGroupName:name groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        group.groupName = name;
        [weakSelf.imStorage.groupDao insertOrUpdate:group];
        [weakSelf notifyGroupProfileChanged:group];
        [weakSelf notifyChangeGroupName:name groupId:groupId error:err];
    }];
}

- (void)setGroupMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId;
{
    //1.检测登录
    //2.检查group是否在本地存在
    //3.成功更新Group内存、更新groupMember到本地
    //3.回调
    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyChangeMsgStatus:status groupId:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postSetGroupMsg:groupId msgStatus:status callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyChangeMsgStatus:status groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        User *owner = [IMEnvironment shareInstance].owner;
        GroupMember *groupMember = [weakSelf.imStorage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:groupId];
        if (groupMember != nil) {
            groupMember.msgStatus = status;
            group.msgStatus = status;
            [weakSelf.imStorage.groupMemberDao insertOrUpdate:groupMember];
        }
        [weakSelf notifyChangeMsgStatus:status groupId:groupId error:err];
    }];
}

- (void)setGroupPushStatus:(IMGroupPushStatus)status groupId:(int64_t)groupId
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postSetGroupPush:groupId pushStatus:status callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyChangeGroupPushStatus:status groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        User *owner = [IMEnvironment shareInstance].owner;
        GroupMember *groupMember = [weakSelf.imStorage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:groupId];
        if (groupMember != nil) {
            groupMember.pushStatus = status;
            [weakSelf.imStorage.groupMemberDao insertOrUpdate:groupMember];
        }
        [weakSelf.imStorage.groupDao load:groupId].pushStatus = status;
        [weakSelf notifyChangeGroupPushStatus:status groupId:groupId error:err];
        
        // 设置群会话免打扰标记
        Conversation *conversation = [weakSelf.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:groupId userRole:eUserRole_Teacher chatType:eChatType_GroupChat];
        if (conversation) {
            if (status == eGroupPushStatus_close) {
                conversation.relation = eConverastion_Relation_Normal;
            } else if (status == eGroupPushStatus_open) {
                conversation.relation = eConversation_Relation_Group_Closed;
            }
            [weakSelf.imStorage.conversationDao update:conversation];
            [weakSelf notifyConversationChanged];
        }
    }];
}

#pragma mark - notify
- (void)notifyGetGroupProfile:(int64_t)groupId group:(Group *)group error:(NSError *)error;
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onGetGroupProfileResult:groupId:group:)]) {
            [delegate onGetGroupProfileResult:error groupId:groupId group:group];
        }
        
    }
}

- (void)notifyLeaveGroup:(int64_t)groupId error:(NSError *)error;
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onLeaveGroupResult:groupId:)]) {
            [delegate onLeaveGroupResult:error groupId:groupId];
        }

    }
}

- (void)notifyDisbandGroup:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onDisbandGroupResult:groupId:)]) {
            [delegate onDisbandGroupResult:error groupId:groupId];
        }

    }
}

- (void)notifyChangeGroupName:(NSString *)name groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onChangeGroupNameResult:newName:groupId:)]) {
            [delegate onChangeGroupNameResult:error newName:name groupId:groupId];
        }
    }
}

- (void)notifyGetGroupMembers:(GroupMemberListData *)members model:(GetGroupMemberModel *)model error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onGetGroupMemberResult:members:)]) {
            [delegate onGetGroupMemberResult:error members:members];
        }
    }
}


- (void)notifyGetGroupMembers:(GroupMemberListData *)members userRole:(IMUserRole)userRole page:(NSInteger)page groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if (userRole == eUserRole_Anonymous) {
            if ([delegate respondsToSelector:@selector(onGetGroupMemberResult:members:page:groupId:)]) {
                [delegate onGetGroupMemberResult:error members:members page:page groupId:groupId];
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(onGetGroupMemberResult:members:userRole:page:groupId:)]) {
                [delegate onGetGroupMemberResult:error members:members userRole:userRole page:page groupId:groupId];
            }
        }
    }
}

- (void)notifyChangeMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onChangeMsgStatusResult:msgStatus:groupId:)]) {
            [delegate onChangeMsgStatusResult:error msgStatus:status groupId:groupId];
        }
    }
}

- (void)notifyChangeGroupPushStatus:(IMGroupPushStatus)status groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onChangePushStatusResult:pushStatus:groupId:)]) {
            [delegate onChangePushStatusResult:error pushStatus:status groupId:groupId];
        }
    }
}


#pragma mark - set get
- (void)setGroupManagerDelegates:(NSHashTable *)groupManagerDelegates
{
    objc_setAssociatedObject(self, &BJGroupMamagerDelegateKey, groupManagerDelegates, OBJC_ASSOCIATION_RETAIN);
}

- (NSHashTable *)groupManagerDelegates
{
    if (objc_getAssociatedObject(self, &BJGroupMamagerDelegateKey) == nil) {
        [self setGroupManagerDelegates:[NSHashTable weakObjectsHashTable]];
    }
    return objc_getAssociatedObject(self, &BJGroupMamagerDelegateKey);
}


@end
